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
          (_: {
            home.packages = [
              pkgs.swaynotificationcenter
              pkgs.nerd-fonts.symbols-only
              pkgs.font-awesome
              pkgs.adwaita-icon-theme
            ];

            xdg.configFile."swaync/config.json".text = builtins.toJSON {
              "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/config.json";
              positionX = "right";
              positionY = "top";
              layer = "top";
              control-center-margin-top = 12;
              control-center-margin-right = 12;
              control-center-width = 300;

              widgets = [
                "buttons-grid"
                "mpris"
                "title"
                "dnd"
                "notifications"
              ];

              "widget-config" = {
                "buttons-grid" = {
                  actions = [
                    {
                      # 👑 FIXED LABELS: Clean text strings returned to normal!
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

            # 👑 THE DEFINITIVE GEOMETRY ALIGNMENT & SCALING CSS SHEET:
            xdg.configFile."swaync/style.css".text = ''
              * {
                  font-family: "Symbols Nerd Font Mono", "Font Awesome 6 Free", "Inter", sans-serif;
              }

              /* Main Dropdown Drawer Box Container */
              .control-center {
                  background: rgba(26, 27, 38, 0.95);
                  border: 1px solid #414868;
                  border-radius: 16px;
                  padding: 12px;
                  box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.5);
              }

              /* Quick Settings Buttons Grid Container Scaling */
              .widget-buttons-grid {
                  background: #1f2335;
                  border-radius: 12px;
                  padding: 6px;
                  margin-bottom: 8px;
              }

              .widget-buttons-grid button {
                  background: #24283b;
                  border: 1px solid #292e42;
                  border-radius: 8px;
                  color: #c0caf5;
                  margin: 3px;
                  padding: 10px 14px;
                  transition: all 0.1s ease-in-out;
              }

              /* 👑 THE COMPLETE LEFT-ALIGNMENT BYPASS FIX:
                 1. We use 'all: unset' to completely strip SwayNC's hardcoded centered constraints! [INDEX: 1.4.1]
                 2. We enforce a 100% width block layout, snapping all text and icons flush left! [INDEX: 1.4.1] */
              .widget-buttons-grid button box {
                  all: unset;
                  display: box !important;
                  text-align: left !important;
                  min-width: 100% !important;
              }

              /* 👑 THE ICON SCALING FIX:
                 Now that the text engine is running flat, we target the icon character node separately!
                 This steps up its font scale to look prominent while preserving your inline row text. */
              .widget-buttons-grid button box label:first-child {
                  font-size: 16px !important;
                  font-weight: normal !important;
                  margin-right: 8px !important;
                  padding-bottom: 1px !important;
              }

              /* Keep the descriptions readable and compact */
              .widget-buttons-grid button box label:last-child {
                  font-size: 12px !important;
                  font-weight: bold !important;
              }

              .widget-buttons-grid button:hover {
                  background: #414868;
                  color: #7aa2f7;
              }
              .widget-buttons-grid button:checked {
                  background: #7aa2f7;
                  color: #1a1b26;
              }

              /* Slim Media Player Box Card Layout */
              .widget-mpris {
                  background: #1f2335;
                  border-radius: 12px;
                  padding: 8px;
                  margin-bottom: 8px;
              }
              .widget-mpris-player {
                  background: #24283b;
                  border-radius: 8px;
                  padding: 8px;
              }
              .widget-mpris-album-art {
                  border-radius: 6px;
                  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
              }
              .widget-mpris-title { font-size: 13px; font-weight: bold; color: #7aa2f7; }
              .widget-mpris-subtitle { font-size: 11px; color: #a9b1d6; }

              .widget-mpris-controls button {
                  color: #c0caf5;
                  font-size: 14px;
                  padding: 4px;
              }
              .widget-mpris-controls button:hover { color: #7aa2f7; }

              /* Notifications Shelf Text Header Split */
              .widget-title {
                  margin-bottom: 6px;
                  padding: 2px 4px;
              }
              .widget-title > label { font-size: 13px; font-weight: bold; color: #bb9af3; }
              .widget-title > button {
                  background: #24283b;
                  border-radius: 6px;
                  color: #f7768e;
                  padding: 3px 6px;
                  font-size: 10px;
              }
              .widget-title > button:hover { background: #f7768e; color: #1a1b26; }

              /* Do Not Disturb Toggle Layout Module Switch */
              .widget-dnd {
                  background: #1f2335;
                  border-radius: 12px;
                  padding: 8px 12px;
                  margin-bottom: 8px;
                  font-size: 12px;
                  color: #c0caf5;
              }
              .widget-dnd switch {
                  border-radius: 10px;
                  background: #24283b;
              }
              .widget-dnd switch:checked { background: #b4f9f8; }

              /* Individual Notification Layout Box Cards */
              .notification-row {
                  background: #1f2335;
                  border: 1px solid #292e42;
                  border-radius: 8px;
                  margin-top: 6px;
                  padding: 10px;
              }
              .notification-title { font-size: 12px; font-weight: bold; color: #7aa2f7; }
              .notification-body { font-size: 11px; color: #c0caf5; margin-top: 1px; }

            '';
          })
        ];
      };
    };
}
