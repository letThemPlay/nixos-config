{ lib, network }:
let
  inherit (lib) listToAttrs nameValuePair;
in

#
# Produces systemd.network.networks as plain data; the network module
# applies it. DNS is left to the resolver, so links only decide
# whether DHCP-offered servers are used.
#
{ model }:

{
  networks = listToAttrs (
    map (
      link:
      nameValuePair (network.query.unitName link) {
        name = link.match;

        networkConfig.DHCP = link.dhcp;

        dhcpV4Config = {
          RouteMetric = link.routeMetric;
          UseDNS = link.useDhcpDns;
        };

        ipv6AcceptRAConfig.UseDNS = link.useDhcpDns;
      }
    ) (network.query.enabled model)
  );
}
