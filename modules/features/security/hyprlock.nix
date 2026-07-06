_: {
  flake.nixosModules.hyprlock = { pkgs, ... }: {
    security.pam.services.hyprlock = { };

    home-manager.sharedModules = [
      ({ config, ... }: {
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

            background = [
              {
                monitor = "";
                path = config.stylix.image;
                blur_passes = 3;
                blur_size = 8;
                color = "rgb(${config.lib.stylix.colors.base00})";
              }
            ];

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

            input-field = [
              {
                monitor = "";
                size = "250, 50";
                outline_thickness = 2;
                dots_size = 0.26;
                dots_spacing = 0.64;
                fade_on_empty = true;

                outer_color = "rgb(${config.lib.stylix.colors.base03})";
                inner_color = "rgb(${config.lib.stylix.colors.base01})";
                font_color = "rgb(${config.lib.stylix.colors.base05})";

                placeholder_text = "<i>Enter Password...</i>";
                position = "0, -20";
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
