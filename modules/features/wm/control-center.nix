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
            home.packages = [ pkgs.swaynotificationcenter ];

            # 👑 THE ACCURATE SCHEMATIC PAYLOAD:
            # We rewrite the JSON parameters to perfectly match SwayNC's required schema keywords!
            xdg.configFile."swaync/config.json".text = builtins.toJSON {
              "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/config.json";
              positionX = "right";
              positionY = "top";
              layer = "top";
              control-center-margin-top = 40;
              control-center-margin-right = 12;
              control-center-width = 340;

              # 👑 Exact schema properties mapping keys!
              widgets = [
                "buttons-grid"
                "mpris"
                "title"
                "dnd"
                "notifications"
              ];

              # 👑 FIXED SYNTAX: SwayNC parses individual button configuration grids
              # directly under the explicit widget definition keyword block!
              "widget-config" = {
                "buttons-grid" = {
                  actions = [
                    {
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

            # Clean styled layout sheets
            xdg.configFile."swaync/style.css".text = ''
              .control-center {
                  background: #1a1b26;
                  border: 2px solid #7aa2f7;
                  border-radius: 12px;
                  padding: 16px;
              }
              .widget-buttons-grid {
                  padding: 8px;
                  margin-bottom: 12px;
              }
              .widget-buttons-grid button {
                  background: #24283b;
                  border-radius: 8px;
                  color: #c0caf5;
                  margin: 6px;
                  padding: 12px;
              }
              .widget-buttons-grid button:hover { background: #414868; }
              .notification-row {
                  background: #24283b;
                  border-radius: 8px;
                  margin-top: 6px;
                  padding: 10px;
              }
            '';
          })
        ];
      };
    };
}
