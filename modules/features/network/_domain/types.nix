{ lib, overrides }:
let
  inherit (lib) mapAttrs mkOption types;

  routing = types.enum [
    "none"
    "client"
    "server"
    "both"
  ];

  #
  # The one tailscale daemon a host runs. Every tailscale tunnel shares
  # these settings; the tunnels differ only in their exit node.
  #
  tailscale = types.submodule {
    options = {

      interface = mkOption {
        type = types.str;
        default = "tailscale0";
        description = "Name of the tailscale tunnel interface.";
      };

      routing = mkOption {
        type = routing;
        default = "client";
        description = ''
          Kernel support for routing: client loosens reverse-path
          filtering so subnet routes and exit nodes work; server also
          forwards. Which routes are used is acceptRoutes and the
          tunnels' exit nodes.
        '';
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "laptop" ];
        description = ''
          Tags the node advertises, without the tag: prefix. The auth
          key must be allowed to use them.
        '';
      };

      acceptDns = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the tailnet's DNS (MagicDNS) is used for its names.";
      };

      acceptRoutes = mkOption {
        type = types.bool;
        default = false;
        description = "Whether subnet routes other nodes advertise are used.";
      };

      authKey.secret = mkOption {
        type = types.str;
        default = "tailscale-authkey";
        description = "ltp.secrets file holding the auth key (secrets/<name>.age).";
      };

    };
  };

  wireguardPeer = types.submodule {
    options = {

      publicKey = mkOption {
        type = types.str;
        description = "The peer's public key.";
      };

      endpoint = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "vpn.example.org:51820";
        description = "Where the peer is reached; null for a peer that only connects in.";
      };

      allowedIPs = mkOption {
        type = types.listOf types.str;

        example = [
          "0.0.0.0/0"
          "::/0"
        ];

        description = ''
          Addresses routed to the peer. 0.0.0.0/0 or ::/0 makes the
          tunnel a full tunnel: it takes the default route.
        '';
      };

      presharedKey.secret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "ltp.secrets file holding the preshared key, if the peer uses one.";
      };

      persistentKeepalive = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        example = 25;
        description = "Seconds between keepalives; useful behind NAT.";
      };

    };
  };

  # A wireguard tunnel's settings; name is the tunnel's.
  wireguard =
    name:
    types.submodule {
      options = {

        interface = mkOption {
          type = types.str;
          default = "wg-${name}";
          description = "Name of the tunnel interface (at most 15 characters).";
        };

        addresses = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "10.0.0.2/32" ];
          description = "Addresses of this host inside the tunnel.";
        };

        privateKey.secret = mkOption {
          type = types.str;
          default = "wireguard-${name}";
          description = "ltp.secrets file holding this host's private key (secrets/<name>.age).";
        };

        dns = mkOption {
          type = types.listOf types.str;
          default = [ ];

          description = ''
            Resolvers reached through the tunnel. A full tunnel sends
            every lookup to them; a split tunnel offers them beside the
            DNS provider.
          '';
        };

        mtu = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
        };

        peers = mkOption {
          type = types.attrsOf wireguardPeer;
          default = { };
          description = "Peers, keyed by name.";
        };

      };
    };

  #
  # A VPN the host can switch on and off. It owns its interface; the
  # links must not match it. Tunnels that take the default route
  # conflict with each other, and tailscale tunnels with each other: one
  # daemon runs one of them at a time.
  #
  tunnel = types.submodule (
    { name, ... }:
    {
      options = {

        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether this tunnel is configured.";
        };

        label = mkOption {
          type = types.str;
          default = name;
          description = "Name the desktop shows.";
        };

        backend = mkOption {
          type = types.str;
          example = "tailscale";
          description = "Backend from the tunnel registry.";
        };

        autostart = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the tunnel comes up at boot.";
        };

        tailscale.exitNode = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "home-server";
          description = ''
            Exit node a tailscale tunnel sends all traffic through; null
            joins only the tailnet.
          '';
        };

        wireguard = mkOption {
          type = wireguard name;
          default = { };
          description = "Settings of a wireguard tunnel.";
        };

      };
    }
  );

  # A tunnel as the model holds it.
  modelTunnel = types.submodule {
    options = {
      name = mkOption { type = types.str; };
      label = mkOption { type = types.str; };
      backend = mkOption { type = types.str; };
      known = mkOption { type = types.bool; };
      autostart = mkOption { type = types.bool; };
      interface = mkOption { type = types.str; };

      unit = mkOption {
        type = types.str;
        description = "systemd unit that holds the tunnel up while it is active.";
      };

      routesAll = mkOption {
        type = types.bool;
        description = "Whether the tunnel takes the default route.";
      };

      conflicts = mkOption {
        type = types.listOf types.str;
        description = "Units of the tunnels this one cannot run beside.";
      };

      tailscale.exitNode = mkOption { type = types.nullOr types.str; };

      wireguard = mkOption { type = wireguard "model"; };
    };
  };

  dnsOverTls = types.enum [
    "yes"
    "opportunistic"
    "no"
  ];

  #
  # Link fields, declared once. `link` is the full entity used by
  # profiles and the model; `linkOverride` is the host-facing partial
  # form: only the fields it defines apply. normalize merges
  # linkDefaults <- profile link <- override.
  #
  linkFields = {

    kind = {
      type = types.enum [
        "wired"
        "wireless"
      ];

      description = ''
        Medium of this link. Wireless links need a wireless backend.
      '';
    };

    match = {
      type = types.str;

      description = ''
        Interface name glob the link applies to.
      '';
    };

    priority = {
      type = types.ints.between 0 99;

      description = ''
        Ordering prefix of the backend unit; lower sorts first.
      '';
    };

    dhcp = {
      type = types.enum [
        "yes"
        "ipv4"
        "ipv6"
        "no"
      ];

      description = ''
        Which address families are configured by DHCP.
      '';
    };

    routeMetric = {
      type = types.ints.unsigned;

      description = ''
        Metric of routes learned on this link; lower is preferred.
      '';
    };

    useDhcpDns = {
      type = types.bool;

      description = ''
        Whether DNS servers offered by DHCP are used. Off by default
        so lookups always go to the configured DNS provider.
      '';
    };

    enable = {
      type = types.bool;

      description = ''
        Whether this link is configured.
      '';
    };

  };

  # Defaults for a link with the given identifier.
  linkDefaults = _id: {
    kind = "wired";
    match = "*";
    priority = 50;
    dhcp = "yes";
    routeMetric = 1024;
    useDhcpDns = false;
    enable = true;
  };

  link = types.submodule (
    { name, ... }:
    {
      options = {

        id = mkOption {
          type = types.str;
          default = name;

          description = ''
            Canonical identifier for this link.

            Assigned during normalization from the attribute name.
          '';
        };

      }
      // mapAttrs (
        field: spec:
        mkOption {
          inherit (spec) type description;
          default = (linkDefaults name).${field};
        }
      ) linkFields;
    }
  );

  #
  # Host override of a profile link, or a new link. Only the fields an
  # override defines replace the profile value (see overrides.nix).
  #
  linkOverride = overrides.type linkFields;

  applyLinkOverride = overrides.apply linkFields;

  profile = types.submodule {
    options = {

      version = mkOption {
        type = types.int;
        default = 1;

        description = ''
          Profile schema version.
        '';
      };

      description = mkOption {
        type = types.lines;

        description = ''
          Human-readable description of this profile.
        '';
      };

      links = mkOption {
        type = types.attrsOf link;
        default = { };

        description = ''
          Links supplied by the profile.
        '';
      };

    };
  };

  provider = types.submodule {
    options = {

      description = mkOption {
        type = types.lines;
      };

      servers = mkOption {
        type = types.listOf types.str;

        description = ''
          Server addresses, without a TLS name.
        '';
      };

      tlsName = mkOption {
        type = types.nullOr types.str;
        default = null;

        description = ''
          Name the servers present for DNS-over-TLS.
        '';
      };

      dnsOverTls = mkOption {
        type = dnsOverTls;
        default = "yes";
      };

      fallback = mkOption {
        type = types.listOf types.str;
        default = [ ];

        description = ''
          Servers used when none of the provider's are reachable.
        '';
      };

    };
  };

  model = types.submodule {
    options = {

      profile = mkOption {
        type = types.submodule {
          options = {

            name = mkOption {
              type = types.str;
            };

            known = mkOption {
              type = types.bool;

              description = ''
                Whether the selected profile exists in the profile registry.
              '';
            };

            version = mkOption {
              type = types.int;
            };

            description = mkOption {
              type = types.lines;
            };

          };
        };

        description = ''
          Metadata describing the selected network profile.
        '';
      };

      backend = mkOption {
        type = types.str;
      };

      links = mkOption {
        type = types.attrsOf link;

        description = ''
          Fully merged links.
        '';
      };

      tailscale = mkOption {
        type = tailscale;
      };

      tunnels = mkOption {
        type = types.attrsOf modelTunnel;

        description = ''
          Enabled tunnels, keyed by name.
        '';
      };

      wireless = mkOption {
        type = types.submodule {
          options.ui = mkOption {
            type = types.bool;
          };

          options.backend = mkOption {
            type = types.str;
          };
        };
      };

      dns = mkOption {
        type = types.submodule {
          options = {

            provider = mkOption {
              type = types.nullOr types.str;
            };

            known = mkOption {
              type = types.bool;

              description = ''
                Whether the provider exists in the provider registry;
                true when no provider is selected.
              '';
            };

            servers = mkOption {
              type = types.listOf types.str;

              description = ''
                Resolver servers, with `#name` appended when the
                provider has a TLS name.
              '';
            };

            dnsOverTls = mkOption {
              type = dnsOverTls;
            };

            dnssec = mkOption {
              type = types.bool;
            };

            fallback = mkOption {
              type = types.listOf types.str;
            };

          };
        };
      };

    };
  };
in
{
  inherit
    routing
    tailscale
    wireguardPeer
    wireguard
    tunnel
    modelTunnel
    dnsOverTls
    linkFields
    linkDefaults
    link
    linkOverride
    applyLinkOverride
    profile
    provider
    model
    ;
}
