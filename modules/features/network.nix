# modules/features/networking.nix
{ inputs, ... }: {
  flake.nixosModules.network =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.ltp.network;

      # Safely access the flake's top-level self source directory
      inherit (inputs) self;

      inherit (lib)
        mkIf
        mkEnableOption
        types
        mkOption
        mapAttrsToList
        attrsets
        lists
        ;

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
      options.ltp.network = {
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
        tailscale = {
          enable = mkEnableOption "Tailscale mesh VPN" // {
            default = false;
          };
          interfaceName = mkOption {
            default = "tailscale0";
            type = types.str;
          };
        };
        nextdns = {
          enable = mkEnableOption "NextDNS configuration" // {
            default = false;
          };
        };
      };

      config = {
        # Note: 'networking.hostName = hostname;' was removed from here.
        # Set 'networking.hostName = "yourhost";' directly in your host flake definitions instead.
        networking = {
          firewall.enable = false;
          dhcpcd.enable = false;
          useDHCP = false;
          useNetworkd = true;
        };

        # Standardised conditional structure using standard 'lib.mkMerge' and 'lib.mkIf'
        # instead of a custom non-standard 'my.mkIfElse' function.
        services.resolved = {
          enable = true;
        }
        // (
          if cfg.nextdns.enable then
            {
              settings = {
                Resolve = {
                  DNSOverTLS = true;
                  DNS =
                    let
                      list = [
                        "45.90.28.0"
                        "2a07:a8c0::"
                        "45.90.30.0"
                        "2a07:a8c1::"
                      ];
                    in
                    lists.forEach list (i: "${i}#965e8b.dns.nextdns.io");
                };
              };
            }
          else
            {
              settings.Resolve = {
                enable = true;
                FallbackDNS = [ "8.8.8.8" ];
              };
            }
        );

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
                ignoredInterfaces = mapAttrsToList (_: value: baseNameOf value.interfaceName) (
                  attrsets.filterAttrs (_: v: v.enable && (builtins.hasAttr "interfaceName" v)) cfg
                );
              in
              ignoredInterfaces;
          };

          # Checks if gnome configuration block exists safely via config check
          services.NetworkManager-wait-online.enable = mkIf (config.ltp.environment.gnome.enable or false
          ) false;
        };

        services.tailscale = mkIf cfg.tailscale.enable {
          enable = true;
          useRoutingFeatures = "client";
          authKeyFile = config.age.secrets.tailscale-authkey.path;
          extraUpFlags = [ "--advertise-tags=tag:server" ];
        };

        age.secrets.tailscale-authkey = mkIf cfg.tailscale.enable {
          file = "${self}/secrets/tailscale-authkey.age";
          mode = "0400";
          owner = "root";
        };
      };
    };
}
