_: {
  #
  # A bottom dock: launchers for the terminal, browser and file manager
  # roles, then the open windows. A second waybar with its own config and
  # style, started in every session.
  #
  flake.nixosModules.dock =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.ltp.desktop.facts) apps;

      launch = role: "uwsm app -- ${lib.escapeShellArgs apps.${role}.command}";
    in
    {
      ltp.desktop.services.dock = {
        description = "Dock";
        exec = [
          "${pkgs.waybar}/bin/waybar"
          "-c"
          "%h/.config/waybar/dock.json"
          "-s"
          "%h/.config/waybar/dock-style.css"
        ];
      };

      home-manager.sharedModules = [
        ({ config, ... }: {
          # The taskbar's icon theme.
          home.packages = [ pkgs.papirus-icon-theme ];

          xdg.configFile."waybar/dock.json".text = builtins.toJSON {
            layer = "top";
            position = "bottom";
            height = 48;
            margin-bottom = 8;

            modules-center = [
              "custom/launcher-term"
              "custom/launcher-browser"
              "custom/launcher-files"
              "wlr/taskbar"
            ];

            "wlr/taskbar" = {
              format = "{icon}";
              icon-theme = "Papirus";
              icon-size = 32;
              on-click = "minimize-raise";
              active-first = false;
              sort-by-app-id = true;
              tooltip-format = "{title}";
              on-click-middle = "close";
            };

            "custom/launcher-term" = {
              format = "";
              on-click = launch "terminal";
              tooltip = false;
            };
            "custom/launcher-browser" = {
              format = "󰈹";
              on-click = launch "browser";
              tooltip = false;
            };
            "custom/launcher-files" = {
              format = "";
              on-click = launch "fileManager";
              tooltip = false;
            };
          };

          xdg.configFile."waybar/dock-style.css".text = ''
            @define-color base00 #${config.lib.stylix.colors.base00};
            @define-color base01 #${config.lib.stylix.colors.base01};
            @define-color base02 #${config.lib.stylix.colors.base02};
            @define-color base03 #${config.lib.stylix.colors.base03};
            @define-color base04 #${config.lib.stylix.colors.base04};
            @define-color base05 #${config.lib.stylix.colors.base05};
            @define-color base0D #${config.lib.stylix.colors.base0D};

            @define-color transparent-base alpha(@base00, 0);

            #custom-launcher-term,
            #custom-launcher-browser,
            #custom-launcher-files {
              font-size: 24px;
              padding: 6px 14px 4px 14px;
              margin: 0 0 0 12px;
              color: @base05;
              background-color: @base01;
              border-radius: 1rem;
              border-bottom: 2px solid transparent;
            }

            #custom-launcher-term:hover,
            #custom-launcher-browser:hover,
            #custom-launcher-files:hover {
              border-bottom: 2px solid @base0D;
            }

            #taskbar {
              margin: 0;
            }

            #taskbar button {
              font-size: 24px;
              background-position: center center;
              background-repeat: no-repeat;
              background-size: 32px;
              border-style: hidden;
              padding: 6px 8px 4px 8px;
              margin: 0 0 0 12px;
              background-color: @base01;
              border-radius: 1rem;
              border-bottom: 2px solid transparent;
            }

            #taskbar button.active {
              border-bottom: 2px solid @base0D;
            }

            #taskbar button:hover {
              border-bottom: 2px solid @base0D;
            }
          '';
        })
      ];
    };
}
