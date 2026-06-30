{ inputs, ... }: {
  flake.nixosModules.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.hyprland;
    in
    {
      options.features.hyprland.enable = lib.mkEnableOption "Hyprland with hy3 tiling window manager" // {
        default = false;
      };

      config = lib.mkIf cfg.enable {
        programs.hyprland = {
          enable = true;
          package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          portalPackage =
            inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        };

        home-manager.sharedModules = [
          (_: {
            wayland.windowManager.hyprland = {
              enable = true;
              package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

              plugins = [
                inputs.hy3.packages.${pkgs.stdenv.hostPlatform.system}.hy3
              ];

              settings = import ./_hyprland/config.nix;
            };
          })
        ];
      };
    };
}
