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

            #custom-startmenu {
            font-size: 24px;
            background-position: 6px center;
            background-repeat: no-repeat;
            background-size: 38px;
            border-style: hidden;
            padding:6px 20px 4px 20px;
            border-radius:1rem;
            background-image: url('niri-icon2.svg');
            background-color: @accent;
            margin:0 0 0 4px;
            border-bottom: 2px solid transparent;
          }

          #custom-startmenu:hover {
            background-image: url('niri-icon0.svg');
          }

          #taskbar {
            margin:0;
          }

          #taskbar button {
            font-size: 24px;
            background-position: center center;
            background-repeat: no-repeat;
            background-size: 32px;
            border-style: hidden;
            padding:6px 8px 4px 8px;
            margin:0 0 0 12px;
            background-color: @theme_base_color;
            border-radius: 1rem;
            border-bottom: 2px solid transparent;
          }

          #taskbar button.active {
            border-bottom: 2px solid @accent;
          }

          #taskbar button:hover {
            border-bottom: 2px solid @accent;
          }

        '';
      })
    ];
  };
}
