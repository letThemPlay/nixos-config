_: {
  #
  # Each user's theme wallpaper, set by swaybg in every session.
  #
  flake.nixosModules.wallpaper =
    { pkgs, ... }:
    {
      ltp.desktop.services.wallpaper = {
        description = "Wallpaper";

        exec =
          { config, osConfig }:
          [
            "${pkgs.swaybg}/bin/swaybg"
            "--output"
            "*"
            "-m"
            "fill"
            "-i"
            # Empty for an unknown theme; the theme subsystem reports it.
            (
              let
                wallpaper = osConfig.ltp.theme.facts.users.${config.home.username}.wallpaper or null;
              in
              if wallpaper == null then "" else "${wallpaper}"
            )
            "--color"
            "#${config.lib.stylix.colors.base00}"
          ];
      };
    };
}
