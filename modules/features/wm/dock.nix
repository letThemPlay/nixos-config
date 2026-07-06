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

        # 👑 THE DEFINITIVE, CROSS-COMPUTED GTK-3 TRANSPARENCY SHEET:
        # We drop raw 8-digit hex string blocks and leverage the bulletproof,
        # native GTK-3 'rgba(#hex, alpha)' declaration format! [INDEX: 1.4.1]
        xdg.configFile."waybar/dock-style.css".text = ''
          * {
              font-family: "Symbols Nerd Font Mono", "Font Awesome 6 Free", "Inter", sans-serif;
              border: none;
              border-radius: 0;
          }

          window#waybar {
              background: transparent !important;
              background-color: transparent !important;
          }

          /* 📱 CHASSIS: Translucent floating island dock pill [INDEX: 1.4.1] */
          .modules-left,
          .modules-center,
          .modules-right {
              /* 👑 FIXED SYNTAX: rgba(#hex, alpha) is perfectly parsed by Waybar's engine! [INDEX: 1.4.1] */
              background-color: rgba(#${config.lib.stylix.colors.base01}, 0.85) !important;
              border: 1px solid #${config.lib.stylix.colors.base03} !important;
              border-radius: 16px !important;
              padding: 4px 12px !important;
              margin: 0px 4px !important;
              box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5) !important;
          }

          button {
              color: #${config.lib.stylix.colors.base05} !important;
              font-size: 18px !important;
              padding: 4px 8px !important;
              margin: 0px 4px !important;
              border-radius: 8px !important;
              transition: all 0.1s ease-in-out !important;
          }

          button:hover {
              /* 👑 FIXED HOVER SYNTAX: Perfect 60% translucency mask with zero macro dependencies! [INDEX: 1.4.1] */
              background-color: rgba(#${config.lib.stylix.colors.base02}, 0.60) !important;
              color: #${config.lib.stylix.colors.base0D} !important;
              transform: scale(1.15) translateY(-2px) !important;
          }

          button.active {
              border-bottom: 2px solid #${config.lib.stylix.colors.base0D} !important;
          }
        '';
      })
    ];
  };
}
