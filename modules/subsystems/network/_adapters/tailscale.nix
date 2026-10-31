_:

#
# The tailscale overlay as plain data; the network module maps it to
# services.tailscale and the agenix secret.
#
{ model }:

let
  inherit (model) overlay;
in
{
  interfaceName = overlay.interface;

  useRoutingFeatures = overlay.routing;

  extraUpFlags =
    (
      if overlay.tags == [ ] then
        [ ]
      else
        [ "--advertise-tags=${builtins.concatStringsSep "," (map (tag: "tag:${tag}") overlay.tags)}" ]
    )
    ++ (if overlay.acceptDns then [ ] else [ "--accept-dns=false" ]);

  inherit (overlay.authKey) secret;

  # Node identity: losing it makes the host a new node on every boot.
  state.directories = [ "/var/lib/tailscale" ];
}
