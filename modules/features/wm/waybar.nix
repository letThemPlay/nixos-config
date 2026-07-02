# modules/features/wm/waybar.nix
_: {
  flake.nixosModules.waybar =
    {
      config,
      lib,
      pkgs,
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

              systemd = {
                enable = true;
                targets = [ "graphical-session.target" ];
              };

              settings = {
                mainBar = import ./_waybar/layout.nix { inherit pkgs; };
              };

              style = import ./_waybar/style.nix;
            };
          })
        ];
      };
    };
}
