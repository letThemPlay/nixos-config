# modules/features/system/security.nix
_: {
  flake.nixosModules.hyprlock = { pkgs, ... }: {
    security.pam.services.hyprlock = { };

    home-manager.sharedModules = [
      ({ config, ... }: {
        # 👑 1. DECLARATIVE IDLE MANAGEMENT CELL (hypridle)
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

        # 👑 2. DECLARATIVE LOCKSCREEN VISUAL CELL (hyprlock)
        programs.hyprlock = {
          enable = true;
          settings = {
            general = {
              disable_loading_bar = true;
              hide_cursor = true;
              grace = 0;
            };

            # 👑 THE INPUT-FIELD REDUNDANCY RESOLUTION:
            # Ripped out the explicit 'input-field' layout block block! Stylix automatically
            # injects, structures, and themes your password input bubble using your live
            # system color codes, clearing out your evaluation clashes permanently! [INDEX: 1.1.6]

            # 📱 Center Digital Clock Layout Still Maintained Natively
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
          };
        };
      })
    ];
  };
}
