_: {
  config.flake.factory.network =
    {
      networkName,
      interfaceName,
      routeMetric,
      ...
    }:
    _: {
      config =
        let
          networkConfig = {
            DHCP = "yes";
            DNSSEC = "no";
            DNSOverTLS = "yes";
            DNS = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          };
        in
        {
          systemd.network = {
            networks."${networkName}" = {
              enable = true;
              name = interfaceName;
              inherit networkConfig;
              dchpV4Config.RouteMetric = routeMetric;
            };
          };
        };
    };
}
