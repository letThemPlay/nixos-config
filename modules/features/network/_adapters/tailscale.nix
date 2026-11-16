{ lib }:

#
# The tailscale tunnels as plain data; the network module maps it to
# services.tailscale, an ltp.secrets file and one unit per tunnel.
#
# The daemon gets no authKeyFile: nixpkgs' autoconnect would log in
# again on every boot (undoing `tailscale down`) and only applies its
# flags on the first login. Each tunnel's unit instead runs
# `tailscale up --reset` with every flag, so a switch always lands on
# exactly that tunnel's settings; the key is only used when a login is
# needed.
#
# secretPath maps an ltp.secrets name to its runtime path.
#
{ model, secretPath }:

let
  inherit (model) tailscale;

  flag = name: value: "--${name}=${lib.boolToString value}";

  up =
    tunnel:
    [
      "tailscale"
      "up"
      "--reset"
      "--auth-key=file:${secretPath tailscale.authKey.secret}"
      (flag "accept-dns" tailscale.acceptDns)
      (flag "accept-routes" tailscale.acceptRoutes)
    ]
    ++
      lib.optional (tailscale.tags != [ ])
        "--advertise-tags=${lib.concatMapStringsSep "," (tag: "tag:${tag}") tailscale.tags}"
    ++ lib.optional (tunnel.tailscale.exitNode != null) "--exit-node=${tunnel.tailscale.exitNode}";

  tunnels = builtins.filter (tunnel: tunnel.backend == "tailscale") (
    builtins.attrValues model.tunnels
  );
in
{
  active = tunnels != [ ];

  daemon = {
    interfaceName = tailscale.interface;

    useRoutingFeatures = tailscale.routing;
  };

  # Root-only, as agenix's defaults (owner root, mode 0400).
  secrets.${tailscale.authKey.secret} = { };

  # pkgs attribute names the commands need on PATH.
  packages = [ "tailscale" ];

  # The daemon the units talk to.
  after = [ "tailscaled.service" ];

  # A first login reaches the coordination server.
  online = true;

  commands = lib.listToAttrs (
    map (tunnel: {
      inherit (tunnel) name;
      value = {
        start = up tunnel;
        stop = [
          "tailscale"
          "down"
        ];
      };
    }) tunnels
  );

  # Node identity: losing it makes the host a new node on every boot.
  state.directories = [ "/var/lib/tailscale" ];
}
