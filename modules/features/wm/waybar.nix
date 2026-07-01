_: {
  flake.nixosModules.waybar =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.features.waybar;
    in
    {
      options.features.waybar.enable = lib.mkEnableOption "Waybar status bar component" // {
        default = false;
      };

      config = lib.mkIf cfg.enable {
        home-manager.sharedModules = [
          (_: {
            programs.waybar = {
              enable = true;
              systemd.enable = false;

              settings = {
                mainBar = import ./_waybar/layout.nix;
              };

              style = import ./_waybar/style.nix;
            };
          })
        ];
      };
    };
}
