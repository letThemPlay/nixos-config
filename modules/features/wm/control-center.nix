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
        # Group network attributes cleanly to pass Statix validation check arrays
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
            # Provision the standalone phone-style panel binary
            home.packages = [ pkgs.swaynotificationcenter ];

            # 👑 THE PHONE DROPDOWN CONFIGURATION BLOCK:
            # We map out a type-safe visual control grid using standard JSON!
            xdg.configFile."swaync/config.json".text = builtins.toJSON {
              "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/config.json";
              positionX = "right";
              positionY = "top";
              layer = "top";
              control-center-margin-top = 40;
              control-center-margin-right = 12;
              control-center-width = 340;

              # 👑 THE DROPDOWN CONTENT DRAWER LAYOUT GRID:
              widgets = [
                "buttons-grid" # 1. Top row mobile style toggle blocks
                "mpris" # 2. Interactive media playback card
                "title" # 3. Notification tracking label header
                "dnd" # 4. Do Not Disturb activation button
                "notifications" # 5. Persistent historical notification list
              ];

              # 📱 Define the individual action button grid parameters (Android Layout)
              widget-config = {
                buttons-grid = {
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

            # Let Stylix handle the base theme styles, but we can match your Niri window designs
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
