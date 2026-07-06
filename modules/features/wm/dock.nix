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

        xdg.configFile."waybar/dock-style.css".text = ''
          @define-color base01 #${config.lib.stylix.colors.base01}D9 ;
          @define-color base02 #${config.lib.stylix.colors.base02}99 ;

          @define-color base03 #${config.lib.stylix.colors.base03} ;
          @define-color base05 #${config.lib.stylix.colors.base05} ;
          @define-color base0D #${config.lib.stylix.colors.base0D} ;

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
              background-color: @base01 !important; /* 👑 Clean hex-alpha execution pass! [INDEX: 1.4.1] */
              border: 1px solid @base03 !important;
              border-radius: 16px !important;
              padding: 4px 12px !important;
              margin: 0px 4px !important;
              box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5) !important;
          }

          button {
              color: @base05 !important;
              font-size: 18px !important;
              padding: 4px 8px !important;
              margin: 0px 4px !important;
              border-radius: 8px !important;
              transition: all 0.15s ease-in-out !important;
          }

          button:hover {
              background-color: @base02 !important;
              color: @base0D !important;
              transform: scale(1.15) translateY(-2px) !important;
          }

          button.active {
              border-bottom: 2px solid @base0D !important;
          }
        '';
      })
    ];
  };
}
