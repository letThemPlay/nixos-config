_: {
  flake.nixosModules.dock = _: {
    home-manager.sharedModules = [
      ({ config, ... }: {
        # 👑 1. THE DOCK CONFIGURATION (JSON):
        # We specify a dedicated custom layout profile for our secondary bottom launcher panel!
        xdg.configFile."waybar/dock.json".text = builtins.toJSON {
          layer = "top";
          position = "bottom";
          height = 48;
          margin-bottom = 8; # 📱 Creates a gorgeous modern floating island card look!

          # Only pull in the specific launcher modules you want pinned to the dock panel
          modules-left = [
            "custom/launcher-term"
            "custom/launcher-browser"
            "custom/launcher-files"
          ];
          modules-center = [ "wlr/taskbar" ]; # 👑 NATIVE NIRI WINDOW TASKS TRACKING! [INDEX: 1.2.1]
          modules-right = [ "custom/control-center-toggle" ];

          # Configure the taskbar to look look and feel exactly like a premium dock canvas
          "wlr/taskbar" = {
            format = "{icon}";
            icon-size = 28;
            tooltip-format = "{title}";
            on-click = "activate";
            on-click-middle = "close";
          };

          # Pinned Application Actions launchers
          "custom/launcher-term" = {
            format = "";
            on-click = "uwsm app -- alacritty";
            tooltip = false;
          };
          "custom/launcher-browser" = {
            format = "  ";
            on-click = "uwsm app -- firefox";
            tooltip = false;
          };
          "custom/launcher-files" = {
            format = "  ";
            on-click = "uwsm app -- alacritty -e yazi";
            tooltip = false;
          };
          "custom/control-center-toggle" = {
            format = "  ";
            on-click = "swaync-client -t -sw";
            tooltip = false;
          };
        };

        # 👑 2. THE DOCK STYLESHEET (CSS):
        # Merges seamlessly with your active Stylix palette configuration tokens! [INDEX: 1.1.6]
        xdg.configFile."waybar/dock-style.css".text = ''
          * {
              font-family: "Symbols Nerd Font Mono", "Font Awesome 6 Free", "Inter", sans-serif;
              border: none;
              border-radius: 0;
          }

          /* Clear the root bar frame background entirely */
          window#waybar {
              background: transparent !important;
          }

          /* 📱 CHASSIS: Creates your standalone compact floating island dock pill! */
          .modules-left,
          .modules-center,
          .modules-right {
              background-color: alpha(#${config.lib.stylix.colors.base01}, 0.85) !important;
              border: 1px solid #${config.lib.stylix.colors.base03} !important;
              border-radius: 16px !important;
              padding: 4px 12px !important;
              margin: 0px 4px !important;
              box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5) !important;
          }

          /* App Icons Launcher Buttons Styling */
          button {
              color: #${config.lib.stylix.colors.base05} !important;
              font-size: 18px !important;
              padding: 4px 8px !important;
              margin: 0px 4px !important;
              border-radius: 8px !important;
              transition: all 0.15s ease-in-out !important;
          }

          button:hover {
              background-color: alpha(#${config.lib.stylix.colors.base02}, 0.6) !important;
              color: #${config.lib.stylix.colors.base0D} !important;
              transform: scale(1.15) translateY(-2px) !important;
          }

          /* Highlights active running application windows in Function Blue! [INDEX: 1.1.6] */
          button.active {
              border-bottom: 2px solid #${config.lib.stylix.colors.base0D} !important;
          }
        '';
      })
    ];
  };
}
