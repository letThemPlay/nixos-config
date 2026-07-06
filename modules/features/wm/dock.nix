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

        # 👑 THE DEFINITIVE CONVERTED DOCK STYLE SHEET:
        # Replicated precisely from your working top-bar color definition format!
        xdg.configFile."waybar/dock-style.css".text = ''
          @define-color base00 #${config.lib.stylix.colors.base00};
          @define-color base01 #${config.lib.stylix.colors.base01};
          @define-color base02 #${config.lib.stylix.colors.base02};
          @define-color base03 #${config.lib.stylix.colors.base03};
          @define-color base04 #${config.lib.stylix.colors.base04};
          @define-color base05 #${config.lib.stylix.colors.base05};
          @define-color base0D #${config.lib.stylix.colors.base0D};

          @define-color transparent-base alpha(@base00, 0);

          * {
              font-family: "Symbols Nerd Font Mono", "Font Awesome 6 Free", "Inter", sans-serif;
              border: none;
              border-radius: 0;
          }

          window#waybar {
              background-color: @transparent-base;
              background: transparent !important;
          }

          /* 📱 CHASSIS: Perfectly styled floating island dock pill modules */
          .modules-left,
          .modules-center,
          .modules-right {
              /* 👑 Uses your exact working macro alpha loop matching format! [INDEX: 1.4.1] */
              background-color: alpha(@base01, 0.85); 
              border: 1px solid @base03;
              border-radius: 16px;
              padding: 4px 12px;
              margin: 0px 4px;
              box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
          }

          button {
              color: @base05;
              font-size: 18px;
              padding: 4px 8px;
              margin: 0px 4px;
              border-radius: 8px;
              transition: all 0.1s ease-in-out;
          }

          button:hover {
              /* 👑 Uses the identical 0.60 alpha macro overlay format! [INDEX: 1.4.1] */
              background-color: alpha(@base02, 0.60);
              color: @base0D;
              transform: scale(1.15) translateY(-2px);
          }

          button.active {
              border-bottom: 2px solid @base0D;
          }
        '';
      })
    ];
  };
}
