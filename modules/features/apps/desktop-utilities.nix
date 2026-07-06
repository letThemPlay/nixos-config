_: {
  flake.nixosModules.desktop-utilities = { pkgs, ... }: {
    home-manager.sharedModules = [
      (_: {
        home.packages = [
          pkgs.grim
          pkgs.slurp
          pkgs.swappy
          pkgs.wl-color-picker
          pkgs.playerctl
          pkgs.awww
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
