{ inputs, ... }: {
  flake.nixosModules.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      themesVault = config.ltp.theme.catalog;
    in
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

        home-manager.users = lib.mapAttrs (_: profile: _: {
          xdg.configFile."niri/config.kdl".text =
            let
              cleanThemeToken = builtins.unsafeDiscardStringContext (profile.theme or "tokyonight");
              selected = themesVault.${cleanThemeToken} or themesVault.tokyonight;

              resolvedImagePath = "${inputs.self}/modules/features/theme/_theme/${selected.imageName}";
            in
            import ./_niri/config-template.nix {
              inherit pkgs;
              profileThemeImage = resolvedImagePath;
            };
        }) config.ltp.users.registry;
      };
    };
}
