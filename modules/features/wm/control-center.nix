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
          (_: {
            home.packages = [
              pkgs.swaynotificationcenter
              pkgs.nerd-fonts.symbols-only
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
                      # 👑 THE ICON UNIFICATION FIX:
                      # We bundle your glyph strings directly inside the single valid label parameter!
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

            # 👑 THE FONT REGISTRY REFINEMENT SHEET:
            xdg.configFile."swaync/style.css".text = ''
              /* 👑 FIXED: We use the exact system font identifier family name "Symbols Nerd Font Mono" */
              /* This explicitly maps your UTF-8 glyph markers across all text labels natively! */
              * {
                  font-family: "Symbols Nerd Font Mono", "Inter", sans-serif;
              }

              .control-center {
                  background: rgba(26, 27, 38, 0.95);
                  border: 1px solid #414868;
                  border-radius: 16px;
                  padding: 12px;
                  box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.5);
              }

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
                  font-weight: bold;
                  font-size: 12px;
                  margin: 3px;
                  padding: 8px;
                  transition: all 0.1s ease-in-out;
              }
              .widget-buttons-grid button:hover {
                  background: #414868;
                  color: #7aa2f7;
              }
              .widget-buttons-grid button:checked {
                  background: #7aa2f7;
                  color: #1a1b26;
              }

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
