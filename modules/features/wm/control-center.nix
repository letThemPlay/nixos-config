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
            home.packages = [ pkgs.swaynotificationcenter ];

            xdg.configFile."swaync/config.json".text = builtins.toJSON {
              "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/config.json";
              positionX = "right";
              positionY = "top";
              layer = "top";
              control-center-margin-top = 12; # Pulled tighter to match your Niri panel struts
              control-center-margin-right = 12;
              control-center-width = 320; # Compact width matching phone quick-settings bounds

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
                      # 👑 ICON FIXED: Standard UTF-8 Nerdfont symbols embedded directly into the buttons!
                      label = "    Network";
                      type = "toggle";
                      active = true;
                      command = "sh -c '${pkgs.networkmanager}/bin/nmcli networking off || ${pkgs.networkmanager}/bin/nmcli networking on'";
                    }
                    {
                      label = "  Bluetooth";
                      type = "toggle";
                      active = true;
                      command = "sh -c '${pkgs.bluez}/bin/bluetoothctl power off || ${pkgs.bluez}/bin/bluetoothctl power on'";
                    }
                    {
                      label = "    Power";
                      type = "button";
                      command = "systemctl poweroff";
                    }
                  ];
                };
              };
            };

            # 👑 THE DESIGN REFINEMENT: Premium iOS/Android Theming Layout Sheet!
            xdg.configFile."swaync/style.css".text = ''
              /* Main Dropdown Container Box */
              .control-center {
                  background: rgba(26, 27, 38, 0.95); /* matching your transparent tokyonight layout */
                  border: 1px solid #414868;
                  border-radius: 16px;
                  padding: 16px;
                  box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.5);
              }

              /* 📱 Quick Settings Buttons Grid Scaling */
              .widget-buttons-grid {
                  background: #24283b;
                  border-radius: 12px;
                  padding: 8px;
                  margin-bottom: 12px;
              }
              .widget-buttons-grid button {
                  background: #1f2335;
                  border: 1px solid #292e42;
                  border-radius: 8px;
                  color: #c0caf5;
                  font-weight: bold;
                  font-size: 13px;
                  margin: 4px;
                  padding: 10px;
                  transition: all 0.15s ease-in-out;
              }
              .widget-buttons-grid button:hover {
                  background: #414868;
                  color: #7aa2f7;
              }
              /* Toggled Active Interfaces Highlight Color Block */
              .widget-buttons-grid button:checked {
                  background: #7aa2f7;
                  color: #1a1b26;
              }

              /*    Media Player Card Layout Refinements */
              .widget-mpris {
                  background: #24283b;
                  border-radius: 12px;
                  padding: 12px;
                  margin-bottom: 12px;
              }
              .widget-mpris-player {
                  padding: 4px;
              }
              .widget-mpris-title { font-size: 14px; font-weight: bold; color: #7aa2f7; }
              .widget-mpris-subtitle { font-size: 11px; color: #a9b1d6; }

              /* Notifications Log Header Split */
              .widget-title {
                  margin-bottom: 8px;
                  padding: 4px;
              }
              .widget-title > label { font-size: 15px; font-weight: bold; color: #bb9af3; }
              .widget-title > button {
                  background: #24283b;
                  border-radius: 6px;
                  color: #f7768e;
                  padding: 4px 8px;
                  font-size: 11px;
              }
              .widget-title > button:hover { background: #f7768e; color: #1a1b26; }

              /* Do Not Disturb Toggle Layout Switch */
              .widget-dnd {
                  background: #24283b;
                  border-radius: 12px;
                  padding: 10px;
                  margin-bottom: 12px;
                  font-size: 13px;
                  color: #c0caf5;
              }
              .widget-dnd switch {
                  border-radius: 12px;
                  background: #1f2335;
              }
              .widget-dnd switch:checked { background: #b4f9f8; }

              /*    Individual Historical Notification Card Items */
              .notification-row {
                  background: #24283b;
                  border: 1px solid #292e42;
                  border-radius: 10px;
                  margin-top: 8px;
                  padding: 12px;
              }
              .notification-content { padding: 4px; }
              .notification-title { font-size: 13px; font-weight: bold; color: #7aa2f7; }
              .notification-body { font-size: 12px; color: #c0caf5; margin-top: 2px; }
            '';
          })
        ];
      };
    };
}
