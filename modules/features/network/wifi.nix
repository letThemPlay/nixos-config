{ inputs, ... }: {
  flake.nixosModules.wifi =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.ltp.network.wireless;
      inherit (lib) types mkOption;
    in
    {
      options.ltp.network.wireless = {
        networkName = mkOption {
          type = types.str;
          default = "25-wireless";
        };
        interfaceName = mkOption {
          type = types.str;
          default = "wl*";
          description = "The target wireless hardware network interface matching string.";
        };
        routeMetric = mkOption {
          default = 2048;
          type = types.int;
        };
      };

      imports =
        let
          networkcfg = {
            inherit (cfg) networkName interfaceName routeMetric;
          };
        in
        [
          (inputs.self.factory.network networkcfg)
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
