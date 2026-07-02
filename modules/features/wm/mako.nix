# modules/features/wm/mako.nix
_: {
  flake.nixosModules.mako =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.mako;
    in
    {
      options.features.mako.enable = lib.mkEnableOption "Mako Wayland notification daemon" // {
        default = false;
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.mako
        ];

        services.dbus.packages = [ pkgs.mako ];

        home-manager.sharedModules = [
          (_: {
            services.mako = {
              enable = true;

              systemd.enable = false;

              layer = "overlay";
              anchor = "top-right";
              margin = "12,12";
              padding = "15";
              borderSize = 2;
              borderRadius = 8;
              defaultTimeout = 5000;
              groupBy = "category";
              maxIconSize = 48;
            };

            stylix.targets.mako.enable = true;

          })
        ];
      };
    };
}
