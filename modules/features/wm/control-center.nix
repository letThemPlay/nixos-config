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
        lib.mkEnableOption "Graphical iOS/Android style system control panel widget via deterministic Astal"
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
        services.dbus.packages = [ pkgs.mako ];

        home-manager.sharedModules = [
          (_: {
            home.packages = [
              pkgs.ags # Aylur's GTK Shell Core Engine v2 [INDEX: 1.3.8]
              pkgs.material-symbols # Android/iOS icon glyph layouts

              (pkgs.writeShellScriptBin "control-center" ''
                #!/bin/sh

                RUN_DIR="/tmp/ags-control-center-$USER"
                mkdir -p "$RUN_DIR"

                cat << 'EOF' > "$RUN_DIR/main.js"
                import App from "resource:///com/github/Aylur/ags/app.js";
                import Widget from "resource:///com/github/Aylur/ags/widget.js";
                import Utils from "resource:///com/github/Aylur/ags/utils.js";
                import Network from "resource:///com/github/Aylur/ags/service/network.js";
                import Bluetooth from "resource:///com/github/Aylur/ags/service/bluetooth.js";

                const QuickButton = (icon, label, callback) => Widget.Button({
                    class_name: "quick-button",
                    on_clicked: callback,
                    child: Widget.Box({
                        vertical: true,
                        children: [
                            Widget.Label({ label: icon, class_name: "icon" }),
                            Widget.Label({ label: label, class_name: "label" })
                        ]
                    })
                });

                const ControlCenterPanel = () => Widget.Box({
                    class_name: "control-center-panel",
                    vertical: true,
                    children: [
                        Widget.Box({
                            class_name: "grid-container",
                            children: [
                                QuickButton("  ", "Network", () => Network.toggleWifi()),
                                QuickButton("", "Bluetooth", () => Bluetooth.toggle()),
                                QuickButton("  ", "Power Off", () => Utils.execAsync("systemctl poweroff"))
                            ]
                        })
                    ]
                });

                const ccWindow = Widget.Window({
                    name: "control-center-window",
                    anchor: ["top", "right"],
                    margin_top: 40,
                    margin_right: 12,
                    child: ControlCenterPanel(),
                    visible: true, // Set to true since our Niri keybind manages spawning/killing the lifecycle
                });

                App.config({ windows: [ccWindow] });
                EOF

                cat << 'EOF' > "$RUN_DIR/style.css"
                .control-center-panel {
                    background-color: #1a1b26;
                    border: 2px solid #7aa2f7;
                    border-radius: 12px;
                    padding: 16px;
                    min-width: 320px;
                }
                .grid-container {
                    display: flex;
                    gap: 12px;
                    justify-content: space-around;
                }
                .quick-button {
                    background-color: #24283b;
                    border-radius: 8px;
                    padding: 16px;
                    color: #c0caf5;
                    min-width: 80px;
                }
                .quick-button:hover { background-color: #414868; }
                .icon { font-size: 24px; color: #7aa2f7; }
                .label { font-size: 12px; margin-top: 4px; }
                EOF

                if ${pkgs.ags}/bin/ags -q -n "control-center-window" 2>/dev/null; then
                    exit 0
                else
                    exec ${pkgs.ags}/bin/ags run --config "$RUN_DIR/main.js" --style "$RUN_DIR/style.css" --name "control-center"
                fi
              '')
            ];
          })
        ];
      };
    };
}
