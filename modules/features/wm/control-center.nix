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

            xdg.configFile."swaync/style.css".text = ''

              :root {
                --border-radius: 22px;
                --cc-bg: transparent;

                --widget-background: rgba(46, 46, 46, 0.7);
                --noti-bg-alpha: 0.0;

                --padding: calc(var(--border-radius) / 2);
              }

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

              /* 📱 FLOATING CARD 1: Quick Settings Grid */
              .widget-buttons-grid {
                  background: #1f2335; 
                  border: 1px solid #292e42;
                  border-radius: 14px;
                  padding: 10px;
                  margin-bottom: 12px;
                  box-shadow: 0 4px 4px rgba(0, 0, 0, 0.6);
              }

              .widget-buttons-grid button {
                  background: #24283b;
                  border: 1px solid #383e5a;
                  border-radius: 8px;
                  color: #c0caf5;
                  font-weight: bold;
                  font-size: 13px;
                  margin: 4px;
                  padding: 10px;
                  transition: all 0.1s ease-in-out;
              }
              .widget-buttons-grid button:hover { background: #414868; color: #7aa2f7; }
              .widget-buttons-grid button:checked { background: #7aa2f7; color: #1a1b26; }

              /*    FLOATING CARD 2: Slim Media Player Box */
              .widget-mpris {
                  background: #1f2335;
                  border: 1px solid #292e42;
                  border-radius: 14px;
                  padding: 10px;
                  margin-bottom: 12px;
                  box-shadow: 0 4px 4px rgba(0, 0, 0, 0.6);
              }
              .widget-mpris-player {
                  background: #24283b;
                  border-radius: 8px;
                  padding: 8px;
              }
              .widget-mpris-album-art {
                  border-radius: 6px;
              }
              .widget-mpris-title { font-size: 13px; font-weight: bold; color: #7aa2f7; }
              .widget-mpris-subtitle { font-size: 11px; color: #a9b1d6; }
              .widget-mpris-controls button { color: #c0caf5; font-size: 14px; padding: 4px; }
              .widget-mpris-controls button:hover { color: #7aa2f7; }

              /* Historical Notifications Logs Header Text Section */
              .widget-title {
                  margin-top: 4px;
                  margin-bottom: 6px;
                  padding: 2px 6px;
              }
              .widget-title > label { font-size: 13px; font-weight: bold; color: #bb9af3; }
              .widget-title > button {
                  background: #1f2335;
                  border: 1px solid #292e42;
                  border-radius: 6px;
                  color: #f7768e;
                  padding: 4px 8px;
                  font-size: 11px;
              }
              .widget-title > button:hover { background: #f7768e; color: #1a1b26; }

              /*    FLOATING CARD 3: Do Not Disturb Toggle Layout Module */
              .widget-dnd {
                  background: #1f2335;
                  border: 1px solid #292e42;
                  border-radius: 14px;
                  padding: 12px;
                  margin-bottom: 12px;
                  font-size: 12px;
                  color: #c0caf5;
                  box-shadow: 0 4px 4px rgba(0, 0, 0, 0.6);
              }
              .widget-dnd switch {
                  border-radius: 10px;
                  background: #24283b;
                  border: 1px solid #383e5a;
              }
              .widget-dnd switch:checked { background: #b4f9f8; }

              /*    FLOATING CARD 4: Individual Incoming Notification Card Items */
              .notification-row {
                  background: #1f2335;
                  border: 1px solid #292e42;
                  border-radius: 12px;
                  margin-top: 8px;
                  padding: 12px;
                  box-shadow: 0 4px 4px rgba(0, 0, 0, 0.6);
              }
              .notification-title { font-size: 12px; font-weight: bold; color: #7aa2f7; }
              .notification-body { font-size: 11px; color: #c0caf5; margin-top: 1px; }

            '';
          })
        ];
      };
    };
}
