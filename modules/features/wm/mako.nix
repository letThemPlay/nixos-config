_: {
  flake.nixosModules.mako =
    { config, lib, ... }:
    let
      cfg = config.features.mako;
    in
    {
      options.features.mako.enable = lib.mkEnableOption "Mako Wayland notification daemon" // {
        default = false;
      };

      config = lib.mkIf cfg.enable {
        home-manager.sharedModules = [
          (_: {
            services.mako = {
              enable = true;

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
