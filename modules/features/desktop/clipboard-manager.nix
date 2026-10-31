_: {
  flake.nixosModules.clipboard-manager =
    { pkgs, ... }:
    let
      # Pick an entry from the clipboard history and copy it back.
      picker = pkgs.writeShellScript "cliphist-picker" ''
        ${pkgs.cliphist}/bin/cliphist list \
          | ${pkgs.fuzzel}/bin/fuzzel --dmenu \
          | ${pkgs.cliphist}/bin/cliphist decode \
          | ${pkgs.wl-clipboard}/bin/wl-copy
      '';
    in
    {
      ltp.desktop.binds."Mod+V".spawn = [ "${picker}" ];

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
