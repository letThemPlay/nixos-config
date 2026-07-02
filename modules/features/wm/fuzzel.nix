_: {
  flake.nixosModules.fuzzel =
    { config, lib, ... }:
    let
      cfg = config.features.fuzzel;
    in
    {
      options.features.fuzzel.enable = lib.mkEnableOption "Fuzzel Wayland application launcher" // {
        default = false;
      };

      config = lib.mkIf cfg.enable {
        home-manager.sharedModules = [
          (_: {
            programs.fuzzel = {
              enable = true;

              settings = {
                main = {
                  terminal = "alacritty";
                  layer = "overlay";
                  width = 40;
                  horizontal-pad = 20;
                  vertical-pad = 15;
                  inner-pad = 10;
                  line-height = 24;
                  fields = "name,generic,comment,exec";
                };
                border = {
                  radius = 8;
                  width = 2;
                };
              };
            };

            stylix.targets.fuzzel.enable = true;
          })
        ];
      };
    };
}
