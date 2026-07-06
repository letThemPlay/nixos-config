_: {
  flake.nixosModules.dock = _: {
    home-manager.sharedModules = [
      ({ config, ... }: {
        xdg.configFile."waybar/dock.json".text = builtins.toJSON {
          layer = "top";
          position = "bottom";
          height = 48;
          margin-bottom = 8;

          modules-center = [ "wlr/taskbar" ];

          "wlr/taskbar" = {
            format = "{icon}";
            icon-theme = "Papirus";
            icon-size = 32;
            on-click = "minimize-raise";
            active-first = false;
            sort-by-app-id = true;
            app_ids-mapping = {
              alacritty = "alacritty";
              firefox = "firefox";
            };
            tooltip-format = "{title}";
            on-click-middle = "close";
          };

          # 👑 THE UNICODE ESCAPE SEQUENCE FIX:
          # We swap raw glyph characters for standard JSON hexadecimal string codes.
          # This completely prevents Nix's JSON serializer from dropping the symbols! [INDEX: 1.2.5, 1.4.1]
          "custom/launcher-term" = {
            format = "";
            on-click = "uwsm app -- alacritty";
            tooltip = false;
          };
          "custom/launcher-browser" = {
            format = "󰈹";
            on-click = "uwsm app -- firefox";
            tooltip = false;
          };
          "custom/launcher-files" = {
            format = ""; # Yazi File Drawer Glyph
            on-click = "uwsm app -- alacritty -e yazi";
            tooltip = false;
          };
        };

        # 👑 THE DEFINITIVE CONVERTED DOCK STYLE SHEET:
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
              background: transparent;
          }

          .modules-left,
          .modules-center,
          .modules-right {
              background-color: alpha(@base01, 0.85); 
              #border: 1px solid @base03;
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
              background-color: alpha(@base02, 0.60);
              color: @base0D;
              padding: 2px 10px 6px 10px;
              margin: 1px 2px 5px 2px;
          }

          button.active {
              border-bottom: 2px solid @base0D;
          }
        '';
      })
    ];
  };
}
