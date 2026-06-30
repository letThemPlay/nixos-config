_: {
  flake.nixosModules.network =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.ltp.network;
      nextDnsActive = config.ltp.network.nextdns.enable or false;

      inherit (lib)
        mkIf
        mkEnableOption
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
      options.ltp.network = {
        enable = mkEnableOption "Default Network configuration" // {
          default = true;
        };
        wifi = {
          enable = mkEnableOption "Wi-Fi configuration" // {
            default = true;
          };
          interfaceName = mkOption {
            default = "wl*";
            type = types.str;
          };
        };
        wired = {
          enable = mkEnableOption "Wired configuration" // {
            default = false;
          };
          interfaceName = mkOption {
            default = "en*";
            type = types.str;
          };
        };
      };

      config = mkIf cfg.enable {
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

        environment.systemPackages = mkIf cfg.wifi.enable [ pkgs.iwgtk ];

        networking.wireless.iwd = {
          inherit (cfg.wifi) enable;
          settings = {
            Network = {
              EnableIPv6 = false;
              RoutePriorityOffset = 300;
            };
            Settings = {
              AutoConnect = true;
            };
          };
        };

        systemd = {
          network = {
            networks = {
              "20-wired" = mkIf cfg.wired.enable {
                enable = true;
                name = cfg.wired.interfaceName;
                inherit networkConfig;
                dhcpV4Config.RouteMetric = 1024;
              };
              "25-wireless" = mkIf cfg.wifi.enable {
                enable = true;
                name = cfg.wifi.interfaceName;
                inherit networkConfig;
                dhcpV4Config.RouteMetric = 2048;
              };
            };

            wait-online.ignoredInterfaces =
              let
                interfaceSubmodules = filterAttrs (
                  _: v: builtins.isAttrs v && (v.enable or false) && (builtins.hasAttr "interfaceName" v)
                ) cfg;
              in
              mapAttrsToList (_: v: baseNameOf v.interfaceName) interfaceSubmodules;
          };

          services.NetworkManager-wait-online.enable = mkIf (config.ltp.environment.gnome.enable or false
          ) false;
        };
      };
    };
}
