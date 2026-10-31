_: {
  #
  # Screen locker (hyprlock) and idle handling (hypridle). hyprlock uses
  # the ext-session-lock protocol, so it works under any compositor.
  #
  flake.nixosModules.locker =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.ltp.desktop) idle;

      # The label font follows the theme (hyprlock resolves it by name).
      font = "${config.ltp.theme.appearance.fonts.sansSerif.name} Bold";
    in
    {
      security.pam.services.hyprlock = { };

      ltp.desktop.binds."Mod+L".spawn = [
        "loginctl"
        "lock-session"
      ];

      home-manager.sharedModules = [
        ({ config, ... }: {
          services.hypridle = {
            enable = true;
            settings = {
              general = {
                lock_cmd = "uwsm app -- ${pkgs.hyprlock}/bin/hyprlock";
                before_sleep_cmd = "loginctl lock-session";
              };

              # One listener per step of the idle policy that is set.
              listener =
                lib.optional (idle.lockAfter != null) {
                  timeout = idle.lockAfter;
                  on-timeout = "loginctl lock-session";
                }
                ++ lib.optional (idle.suspendAfter != null) {
                  timeout = idle.suspendAfter;
                  on-timeout = "systemctl suspend";
                };
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
                  font_family = font;
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
