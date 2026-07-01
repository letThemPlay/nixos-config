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
          withUWSM = true;
          package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          portalPackage =
            inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        };

        security.pam.services.login.enableGnomeKeyring = true;
        services.dbus.enable = true;
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        };

        home-manager.sharedModules = [
          (_: {
            wayland.windowManager.hyprland = {
              enable = true;
              package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

              systemd.enable = false;

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
