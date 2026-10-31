_: {
  flake.nixosModules.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {

      config = {
        programs.niri = {
          enable = true;
          package = pkgs.niri;
        };

        environment = {
          systemPackages = [
            pkgs.swaybg
            pkgs.uwsm
          ];
        };

        security.pam.services.login.enableGnomeKeyring = true;
        services.dbus.enable = true;
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        };

        # Users with an unknown theme are left out; the theme subsystem
        # reports them.
        home-manager.users = lib.mapAttrs (_: userTheme: _: {
          xdg.configFile."niri/config.kdl".text = import ./_niri/config-template.nix {
            inherit pkgs;
            profileThemeImage = userTheme.wallpaper;
          };
        }) (lib.filterAttrs (_: userTheme: userTheme.known) config.ltp.theme.facts.users);
      };
    };
}
