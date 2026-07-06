_: {
  flake.nixosModules.dock = _: {
    home-manager.sharedModules = [
      ({ config, ... }: {
        xdg.configFile."waybar/dock.json".text = builtins.toJSON {
          layer = "top";
          position = "bottom";
          height = 48;
          margin-bottom = 8;

          modules-left = [
            "custom/launcher-term"
            "custom/launcher-browser"
            "custom/launcher-files"
          ];
          modules-center = [ "wlr/taskbar" ];
          modules-right = [ "custom/control-center-toggle" ];

          "wlr/taskbar" = {
            format = "{icon}";
            icon-size = 28;
            tooltip-format = "{title}";
            on-click = "activate";
            on-click-middle = "close";
          };

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

        # 👑 THE DEFINITIVE RE-ENGINEERED CSS SHEET:
        xdg.configFile."waybar/dock-style.css".text = ''
          /* 👑 FIXED SYNTAX: Using standard CSS custom properties inside the wildcard block.
             This bypasses the fragile GTK macro engine entirely, removing all semicolon errors! [INDEX: 1.4.1] */
          * {
              font-family: "Symbols Nerd Font Mono", "Font Awesome 6 Free", "Inter", sans-serif;
              border: none;
              border-radius: 0;
              
              /* System variable mappings mapped natively through your Stylix tokens [INDEX: 1.1.6, 1.4.1] */
              --base01: #${config.lib.stylix.colors.base01}D9;
              --base02: #${config.lib.stylix.colors.base02}99;
              --base03: #${config.lib.stylix.colors.base03};
              --base05: #${config.lib.stylix.colors.base05};
              --base0D: #${config.lib.stylix.colors.base0D};
          }

          window#waybar {
              background: transparent !important;
              background-color: transparent !important;
          }

          /* 📱 CHASSIS: Premium translucent floating island dock pill [INDEX: 1.4.1] */
          .modules-left,
          .modules-center,
          .modules-right {
              background-color: var(--base01) !important; /* 👑 Clean, native runtime variable query! [INDEX: 1.4.1] */
              border: 1px solid var(--base03) !important;
              border-radius: 16px !important;
              padding: 4px 12px !important;
              margin: 0px 4px !important;
              box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5) !important;
          }

          button {
              color: var(--base05) !important;
              font-size: 18px !important;
              padding: 4px 8px !important;
              margin: 0px 4px !important;
              border-radius: 8px !important;
              transition: all 0.1s ease-in-out !important;
          }

          button:hover {
              background-color: var(--base02) !important;
              color: var(--base0D) !important;
              transform: scale(1.15) translateY(-2px) !important;
          }

          button.active {
              border-bottom: 2px solid var(--base0D) !important;
          }
        '';
      })
    ];
  };
}
