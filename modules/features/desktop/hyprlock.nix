_: {
  flake.nixosModules.hyprlock = { pkgs, ... }: {
    security.pam.services.hyprlock = { };

    home-manager.sharedModules = [
      ({ config, lib, ... }: {
        services.hypridle = {
          enable = true;
          settings = {
            general = {
              lock_cmd = "uwsm app -- ${pkgs.hyprlock}/bin/hyprlock";
              before_sleep_cmd = "loginctl lock-session";
            };

            listener = [
              {
                timeout = 300;
                on-timeout = "loginctl lock-session";
              }
              {
                timeout = 900;
                on-timeout = "systemctl suspend";
              }
            ];
          };
        };

        programs.hyprlock = {
          enable = true;
          settings = {
            general = {
              disable_loading_bar = true;
              hide_cursor = true;
              grace = 0;
            };

            label = [
              {
                monitor = "";
                text = "$TIME";
                color = "rgb(${config.lib.stylix.colors.base05})";
                font_size = 64;
                font_family = "Inter Bold";
                position = "0, 150";
                halign = "center";
                valign = "center";
              }
            ];

            input-field = lib.mkForce [
              {
                monitor = "";

                size = "200, 45";

                rounding = 6; # Lower numbers create sharp tech corners; use -1 for pure circular pills.

                outline_thickness = 1;
                dots_size = 0.25;
                dots_spacing = 0.50;
                fade_on_empty = true;

                outer_color = "rgb(${config.lib.stylix.colors.base03})";
                inner_color = "rgb(${config.lib.stylix.colors.base01})";
                font_color = "rgb(${config.lib.stylix.colors.base05})";

                placeholder_text = "<i>Enter Password...</i>";
                position = "0, -40";
                halign = "center";
                valign = "center";
              }
            ];
          };
        };
      })
    ];
  };
}
