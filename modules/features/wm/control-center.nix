# modules/features/wm/control-center.nix
_: {
  flake.nixosModules.control-center =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.control-center;
    in
    {
      options.features.control-center.enable =
        lib.mkEnableOption "Graphical iOS/Android style system control panel widget via SwayNC"
        // {
          default = false;
        };

      config = lib.mkIf cfg.enable {
        networking = {
          networkmanager = {
            enable = true;
            wifi.backend = "iwd";
          };
          wireless.iwd.enable = true;
        };

        hardware.bluetooth.enable = true;

        home-manager.sharedModules = [
          # 👑 INJECT SYSTEM VARIABLES: We request the active home-manager scope 'config' handle
          # to pull your cryptographic system colors cleanly out of the nix store engine! [INDEX: 1.1.6]
          ({ config, ... }: {
            home.packages = [
              pkgs.swaynotificationcenter
              pkgs.nerd-fonts.symbols-only
              pkgs.font-awesome
              pkgs.adwaita-icon-theme
            ];

            # 👑 Prevent Stylix from forcing its own opaque background wrappers over our clean layout cards! [INDEX: 1.1.6]
            stylix.targets.swaync.enable = false;

            xdg.configFile."swaync/config.json".text = builtins.toJSON {
              "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/config.json";
              positionX = "right";
              positionY = "top";
              layer = "top";
              control-center-margin-top = 12;
              control-center-margin-right = 12;
              control-center-width = 300;

              # 👑 YOUR CUSTOM WIDGET RE-ORDER MATCH MATRIX:
              widgets = [
                "mpris"
                "title"
                "notifications"
                "buttons-grid"
              ];

              "widget-config" = {
                "buttons-grid" = {
                  actions = [
                    {
                      label = "   Network";
                      type = "toggle";
                      active = true;
                      command = "sh -c '${pkgs.networkmanager}/bin/nmcli networking off || ${pkgs.networkmanager}/bin/nmcli networking on'";
                    }
                    {
                      label = "   Bluetooth";
                      type = "toggle";
                      active = true;
                      command = "sh -c '${pkgs.bluez}/bin/bluetoothctl power off || ${pkgs.bluez}/bin/bluetoothctl power on'";
                    }
                    {
                      label = "   Power";
                      type = "button";
                      command = "systemctl poweroff";
                    }
                  ];
                };
              };
            };

            # 👑 THE REFINED, SYSTEM-THEMED CUSTOM STYLIZATION BLOCK:
            xdg.configFile."swaync/style.css".text = ''
              :root {
                --border-radius: 22px;
                --cc-bg: transparent;
                --widget-background: rgba(46, 46, 46, 0.7);
                --noti-bg-alpha: 0.0;
                --padding: calc(var(--border-radius) / 2);
              }

              * {
                  font-family: "Symbols Nerd Font Mono", "Font Awesome 6 Free", "Inter", sans-serif;
              }

              /* Clear our parent layer background masks completely [INDEX: 1.4.1] */
              .blank-window,
              window,
              #window,
              .control-center,
              .control-center-box,
              box.control-center {
                  background: transparent !important;
                  background-color: rgba(0, 0, 0, 0) !important;
                  border: none !important;
                  box-shadow: none !important;
                  padding: 0px;
                  margin: 0px;
              }

              /* 📱 FLOATING CARD 1: Quick Settings Grid Wrapper */
              .widget-buttons-grid {
                  /* 👑 Synchronized natively with your Stylix Dark Base background color! [INDEX: 1.1.6] */
                  background: #${config.lib.stylix.colors.base01}; 
                  border: 1px solid #${config.lib.stylix.colors.base03};
                  border-radius: 14px;
                  padding: 10px;
                  margin-bottom: 12px;
                  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.6);
              }

              .widget-buttons-grid button {
                  background: #${config.lib.stylix.colors.base02};
                  border: 1px solid #${config.lib.stylix.colors.base03};
                  border-radius: 8px;
                  color: #${config.lib.stylix.colors.base05};
                  font-weight: bold;
                  font-size: 13px;
                  margin: 4px;
                  padding: 10px;
                  transition: all 0.1s ease-in-out;
              }
              .widget-buttons-grid button:hover { 
                  background: #${config.lib.stylix.colors.base03}; 
                  color: #${config.lib.stylix.colors.base0D}; 
              }
              .widget-buttons-grid button:checked { 
                  background: #${config.lib.stylix.colors.base0D}; 
                  color: #${config.lib.stylix.colors.base00}; 
              }

              /*    FLOATING CARD 2: Slim Media Player Box at the Top! */
              .widget-mpris {
                  background: #${config.lib.stylix.colors.base01}; 
                  border: 1px solid #${config.lib.stylix.colors.base03};
                  border-radius: 14px;
                  padding: 10px;
                  margin-bottom: 12px;
                  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.6);
              }
              .widget-mpris-player {
                  background: #${config.lib.stylix.colors.base02};
                  border-radius: 8px;
                  padding: 8px;
              }
              .widget-mpris-album-art {
                  border-radius: 6px;
              }
              .widget-mpris-title { font-size: 13px; font-weight: bold; color: #${config.lib.stylix.colors.base0D}; }
              .widget-mpris-subtitle { font-size: 11px; color: #${config.lib.stylix.colors.base04}; }
              .widget-mpris-controls button { color: #${config.lib.stylix.colors.base05}; font-size: 14px; padding: 4px; }
              .widget-mpris-controls button:hover { color: #${config.lib.stylix.colors.base0D}; }

              /* Historical Notifications Logs Header Section */
              .widget-title {
                  margin-top: 4px;
                  margin-bottom: 6px;
                  padding: 2px 6px;
              }
              .widget-title > label { font-size: 13px; font-weight: bold; color: #${config.lib.stylix.colors.base0E}; }
              .widget-title > button {
                  background: #${config.lib.stylix.colors.base01};
                  border: 1px solid #${config.lib.stylix.colors.base03};
                  border-radius: 6px;
                  color: #${config.lib.stylix.colors.base08};
                  padding: 4px 8px;
                  font-size: 11px;
              }
              .widget-title > button:hover { background: #${config.lib.stylix.colors.base08}; color: #${config.lib.stylix.colors.base00}; }

              /*    FLOATING CARD 3: Do Not Disturb Toggle Layout Module */
              .widget-dnd {
                  background: #${config.lib.stylix.colors.base01};
                  border: 1px solid #${config.lib.stylix.colors.base03};
                  border-radius: 14px;
                  padding: 12px;
                  margin-bottom: 12px;
                  font-size: 12px;
                  color: #${config.lib.stylix.colors.base05};
                  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.6);
              }
              .widget-dnd switch {
                  border-radius: 10px;
                  background: #${config.lib.stylix.colors.base02};
                  border: 1px solid #${config.lib.stylix.colors.base03};
              }
              .widget-dnd switch:checked { background: #${config.lib.stylix.colors.base0C}; }

              /*    FLOATING CARD 4: Individual Incoming Notification Card Items */
              .notification-row {
                  background: #${config.lib.stylix.colors.base01};
                  border: 1px solid #${config.lib.stylix.colors.base03};
                  border-radius: 12px;
                  margin-top: 8px;
                  padding: 12px;
                  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.6);
              }
              .notification-title { font-size: 12px; font-weight: bold; color: #${config.lib.stylix.colors.base0D}; }
              .notification-body { font-size: 11px; color: #${config.lib.stylix.colors.base05}; margin-top: 1px; }
            '';
          })
        ];
      };
    };
}
