{ inputs, ... }: {
  flake.nixosModules.wifi =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.ltp.network.wifi;
    in
    {
      options.ltp.network.wifi = {
        interfaceName = lib.mkOption {
          type = lib.types.str;
          default = "wl*";
          description = "The target wireless hardware network interface matching string.";
        };
      };

      imports = [
        (inputs.self.factory.network {
          networkName = "25-wireless";
          inherit (cfg.wireless) interfaceName;
          routeMetric = 2048;
        })
      ];

      config = {
        environment.systemPackages = [ pkgs.iwgtk ];

        networking.wireless.iwd = {
          enable = true;
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
      };
    };
}
