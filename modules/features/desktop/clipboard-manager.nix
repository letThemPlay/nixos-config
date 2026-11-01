_: {
  flake.nixosModules.clipboard-manager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # The launcher role's dmenu mode; validation reports a launcher without one.
      dmenu = config.ltp.desktop.facts.apps.launcher.dmenu or null;

      # Pick an entry from the clipboard history and copy it back.
      picker = pkgs.writeShellScript "cliphist-picker" ''
        ${pkgs.cliphist}/bin/cliphist list \
          | ${lib.escapeShellArgs (if dmenu == null then [ "false" ] else dmenu)} \
          | ${pkgs.cliphist}/bin/cliphist decode \
          | ${pkgs.wl-clipboard}/bin/wl-copy
      '';
    in
    {
      ltp.desktop = {
        binds."Mod+V".spawn = [ "${picker}" ];

        dmenuConsumers = [ "clipboard" ];
      };

      home-manager.sharedModules = [
        (_: {
          home.packages = [
            pkgs.cliphist
            pkgs.wl-clipboard
          ];

          services.cliphist = {
            enable = true;
            allowImages = true;
          };
        })
      ];
    };
}
