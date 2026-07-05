_: {
  flake.nixosModules.network =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.network;
      nextDnsActive = config.ltp.network.nextdns.enable or false;

      inherit (lib)
        types
        mkOption
        mapAttrsToList
        filterAttrs
        ;

      networkConfig = {
        DHCP = "yes";
        DNSSEC = "no";
        DNSOverTLS = "yes";
        DNS =
          if nextDnsActive then
            [ ]
          else
            [
              "1.1.1.1"
              "1.0.0.1"
            ];
      };
    in
    {
      options.features.network = {
        wired = {
          interfaceName = mkOption {
            default = "en*";
            type = types.str;
          };
        };
      };

      config = {
        networking = {
          firewall.enable = false;
          dhcpcd.enable = false;
          useDHCP = false;
          useNetworkd = true;
        };

        services.resolved = {
          enable = true;
          settings.Resolve =
            if nextDnsActive then
              {
                DNSOverTLS = true;
                DNS = map (i: "${i}#965e8b.dns.nextdns.io") [
                  "45.90.28.0"
                  "2a07:a8c0::"
                  "45.90.30.0"
                  "2a07:a8c1::"
                ];
              }
            else
              {
                DNSOverTLS = "yes";
                FallbackDNS = [ "8.8.8.8" ];
              };
        };

        systemd = {
          network = {
            networks."20-wired" = {
              enable = true;
              name = cfg.wired.interfaceName;
              inherit networkConfig;
              dhcpV4Config.RouteMetric = 1024;
            };

            wait-online.ignoredInterfaces =
              let
                interfaceSubmodules = filterAttrs (
                  _: v: builtins.isAttrs v && (v.enable or false) && (builtins.hasAttr "interfaceName" v)
                ) cfg;
              in
              mapAttrsToList (_: v: baseNameOf v.interfaceName) interfaceSubmodules;
          };
        };
      };
    };
}
