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

        security.pam.services.login.enableGnomeKeyring = true;
        services.dbus.enable = true;
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        };

        home-manager.sharedModules = [
          (_: {
            stylix.targets.niri.enable = true;
            xdg.configFile."niri/config.kdl".source = ./_niri/config.kdl;
          })
        ];
      };
    };
}
