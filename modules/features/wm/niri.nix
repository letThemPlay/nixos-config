_: {
  flake.nixosModules.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.niri;
    in
    {
      options.features.niri.enable = lib.mkEnableOption "Niri scrollable-tiling Wayland compositor" // {
        default = false;
      };

      config = lib.mkIf cfg.enable {
        programs.niri = {
          enable = true;
          package = pkgs.niri;
        };

        environment = {
          systemPackages = [ pkgs.swaybg ];
          variables = {
            "WLR_RENDER_DRM_DEVICE" = "/dev/dri/renderD128";
          };
        };

        security.pam.services.login.enableGnomeKeyring = true;
        services.dbus.enable = true;
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        };

        home-manager.sharedModules = [
          (_: {
            home.extraProfileCommands = ''
              export HM_DISPLAY_VARS="WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY"
            '';
          })
          (_: {
            xdg.configFile."niri/config.kdl".source = ./_niri/config.kdl;
          })
        ];
      };
    };
}
