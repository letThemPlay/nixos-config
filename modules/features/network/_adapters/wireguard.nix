{ lib }:
let
  inherit (lib)
    any
    attrValues
    concatMap
    filter
    imap0
    listToAttrs
    mapAttrsToList
    nameValuePair
    optional
    optionalAttrs
    replaceStrings
    ;
in

#
# The wireguard tunnels as networkd netdevs and networks; the network
# module applies them. Each link stays down (ActivationPolicy=manual)
# until its tunnel's unit brings it up, so the unit is the only switch.
#
# A full tunnel keeps the endpoint reachable the way wg-quick does: the
# peer routes go to the tunnel's own table, wireguard marks its own
# packets, and policy rules send every unmarked packet to that table
# unless the main table has a more specific route. Each full tunnel gets
# its own table, mark and rule priorities, so their rules never collide;
# a tunnel that is down leaves its table empty and its rules fall
# through.
#
# secretPath maps an ltp.secrets name to its runtime path.
#
{ model, secretPath }:

let
  tunnels = filter (tunnel: tunnel.backend == "wireguard") (attrValues model.tunnels);

  # Table (and firewall mark) of each full tunnel, by name.
  tables = listToAttrs (
    imap0 (index: tunnel: nameValuePair tunnel.name (51820 + index)) (
      filter (tunnel: tunnel.routesAll) tunnels
    )
  );

  # Rule priorities of each full tunnel, below the main table's 32766.
  priority = tunnel: 1000 + 2 * (tables.${tunnel.name} - 51820);

  #
  # tailscaled keeps the tailnet's routes in its own table, 52, behind
  # rules from priority 5210 on, after a full tunnel's rules, which
  # would send tailnet traffic into the tunnel. A rule ahead of them
  # looks in table 52 first, skipping any default route there (an exit
  # node's, which never runs beside a full tunnel anyway).
  #
  tailscaleTable = 52;

  hasTailscale = any (tunnel: tunnel.backend == "tailscale") (attrValues model.tunnels);

  tailnetPriority = tunnel: 900 + tables.${tunnel.name} - 51820;

  peerConfig =
    peer:
    {
      PublicKey = peer.publicKey;
      AllowedIPs = peer.allowedIPs;
    }
    // optionalAttrs (peer.endpoint != null) { Endpoint = peer.endpoint; }
    // optionalAttrs (peer.presharedKey.secret != null) {
      PresharedKeyFile = secretPath peer.presharedKey.secret;
    }
    // optionalAttrs (peer.persistentKeepalive != null) {
      PersistentKeepalive = peer.persistentKeepalive;
    };

  netdev =
    tunnel:
    let
      inherit (tunnel) wireguard;
    in
    {
      netdevConfig = {
        Kind = "wireguard";
        Name = tunnel.interface;
      }
      // optionalAttrs (wireguard.mtu != null) { MTUBytes = toString wireguard.mtu; };

      wireguardConfig = {
        PrivateKeyFile = secretPath wireguard.privateKey.secret;

        RouteTable = if tunnel.routesAll then tables.${tunnel.name} else "main";
      }
      // optionalAttrs tunnel.routesAll { FirewallMark = tables.${tunnel.name}; };

      wireguardPeers = map peerConfig (attrValues wireguard.peers);
    };

  network =
    tunnel:
    let
      inherit (tunnel) wireguard;

      table = tables.${tunnel.name};

      hasDns = wireguard.dns != [ ];

      fullDns = tunnel.routesAll && hasDns;
    in
    {
      matchConfig.Name = tunnel.interface;

      address = wireguard.addresses;

      inherit (wireguard) dns;

      linkConfig = {
        ActivationPolicy = "manual";

        # A switchable tunnel never holds up boot.
        RequiredForOnline = "no";
      };

      #
      # The DNS provider's DNS-over-TLS mode is global, so a link that
      # sets none inherits it, and a VPN's resolver answers plain DNS
      # only: under strict mode every lookup through the tunnel fails.
      # The tunnel already encrypts the queries.
      #
      networkConfig =
        optionalAttrs hasDns { DNSOverTLS = "no"; }
        # Every lookup goes through the tunnel while it is up.
        // optionalAttrs fullDns { DNSDefaultRoute = true; };
    }
    // optionalAttrs fullDns {
      domains = [ "~." ];
    }
    // optionalAttrs tunnel.routesAll {
      routingPolicyRules =
        optional hasTailscale {
          Table = tailscaleTable;
          SuppressPrefixLength = 0;
          Priority = tailnetPriority tunnel;
          Family = "both";
        }
        ++ [
          {
            Table = "main";
            SuppressPrefixLength = 0;
            Priority = priority tunnel;
            Family = "both";
          }
          {
            FirewallMark = table;
            InvertRule = true;
            Table = table;
            Priority = priority tunnel + 1;
            Family = "both";
          }
        ];
    };

  # Unit name of the network device: systemd escapes "-" in the path.
  deviceUnit =
    interface: "sys-subsystem-net-devices-${replaceStrings [ "-" ] [ "\\x2d" ] interface}.device";

  # networkd's own unit files sort before the links' (priority 10).
  unitName = tunnel: "10-${tunnel.name}";

  secretFile = {
    owner = "systemd-network";
    group = "systemd-network";
    mode = "0400";
  };
in
{
  active = tunnels != [ ];

  netdevs = listToAttrs (map (tunnel: nameValuePair (unitName tunnel) (netdev tunnel)) tunnels);

  networks = listToAttrs (map (tunnel: nameValuePair (unitName tunnel) (network tunnel)) tunnels);

  # networkd reads the keys, so it owns them.
  secrets = listToAttrs (
    concatMap (
      tunnel:
      [ (nameValuePair tunnel.wireguard.privateKey.secret secretFile) ]
      ++ mapAttrsToList (_: peer: nameValuePair peer.presharedKey.secret secretFile) (
        lib.filterAttrs (_: peer: peer.presharedKey.secret != null) tunnel.wireguard.peers
      )
    ) tunnels
  );

  # networkctl comes with the system's systemd, on every unit's PATH.
  packages = [ ];

  after = [ "systemd-networkd.service" ];

  # Wireguard needs no connection to come up.
  online = false;

  commands = listToAttrs (
    map (
      tunnel:
      nameValuePair tunnel.name {
        start = [
          "networkctl"
          "up"
          tunnel.interface
        ];

        stop = [
          "networkctl"
          "down"
          tunnel.interface
        ];

        # At boot the unit waits for networkd to create the device.
        requires = [ (deviceUnit tunnel.interface) ];
      }
    ) tunnels
  );

  # The keys come from ltp.secrets; nothing else lasts.
  state = { };
}
