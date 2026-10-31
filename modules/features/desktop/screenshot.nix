_: {
  flake.nixosModules.screenshot =
    { pkgs, ... }:
    let
      # Select a region and annotate it.
      region = pkgs.writeShellScript "screenshot-region" ''
        ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
      '';
    in
    {
      ltp.desktop.binds = {
        "Ctrl+Shift+S".spawn = [ "${region}" ];
        "Mod+Shift+C".spawn = [ "${pkgs.wl-color-picker}/bin/wl-color-picker" ];
      };

      home-manager.sharedModules = [
        (_: {
          home.packages = [
            pkgs.grim
            pkgs.slurp
            pkgs.swappy
            pkgs.wl-color-picker
          ];

          home.file.".config/swappy/config".text = ''
            [Default]
            save_dir=$HOME/Pictures/Screenshots
            save_filename_format=Screenshot_%Y%m%d_%H%M%S.png
            show_panel=false
            line_size=5
          '';
        })
      ];
    };
}
