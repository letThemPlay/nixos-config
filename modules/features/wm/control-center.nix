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
        lib.mkEnableOption "Graphical iOS/Android style system control panel widget via Astal v2"
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
            # Provision our core asset tracking packages
            home.packages = [
              pkgs.ags # Aylur's GTK Shell Core Engine v2 [INDEX: 1.3.1]
              pkgs.material-symbols # Android/iOS icon glyph layouts

              # 👑 THE ERROR-FREE BUNDLED BINARY FIX:
              # writeShellScriptBin automatically prepends a safe Linux shell header (#!/bin/sh).
              # This guarantees your terminal runs the script as a shell loop, rather than trying to parse JS raw!
              (pkgs.writeShellScriptBin "control-center" ''
                #!/bin/sh

                # Build a temporary workspace directory to store configuration streams securely
                RUN_DIR="/tmp/ags-control-center-$USER"
                mkdir -p "$RUN_DIR"

                # 👑 1. WE PACK THE ASTAL JAVASCRIPT TARGET DOWN TO AN ISOLATED TEMP FILE:
                cat << 'EOF' > "$RUN_DIR/main.js"
                import App from "gi://AstalApp";
                import Widget from "gi://AstalWidget";
                import Utils from "gi://AstalUtils";
                import Network from "gi://AstalNetwork";
                import Bluetooth from "gi://AstalBluetooth";

                const QuickButton = (icon, label, callback) => Widget.Button({
                    className: "quick-button",
                    onClicked: callback,
                    child: Widget.Box({
                        vertical: true,
                        children: [
                            Widget.Label({ label: icon, className: "icon" }),
                            Widget.Label({ label: label, className: "label" })
                        ]
                    })
                });

                const ControlCenterPanel = () => Widget.Box({
                    className: "control-center-panel",
                    vertical: true,
                    children: [
                        Widget.Box({
                            className: "grid-container",
                            children: [
                                QuickButton("  ", "Network", () => {
                                    const nw = Network.get_default();
                                    if (nw) nw.wifi.toggle();
                                }),
                                QuickButton("", "Bluetooth", () => {
                                    const bt = Bluetooth.get_default();
                                    if (bt) bt.toggle();
                                }),
                                QuickButton("  ", "Power Off", () => Utils.execAsync("systemctl poweroff"))
                            ]
                        })
                    ]
                });

                App.start({
                    instanceName: "control-center",
                    windows: [
                        Widget.Window({
                            name: "control-center-window",
                            anchor: Widget.WindowAnchor.TOP | Widget.WindowAnchor.RIGHT,
                            marginTop: 40,
                            marginRight: 12,
                            child: ControlCenterPanel(),
                        })
                    ]
                });
                EOF

                # 👑 2. THE COMPACT RUNTIME EXECUTION OVERRIDE:
                # We hop inside our temporary sandbox directory and feed the code into ags natively! [INDEX: 1.2.1]
                cd "$RUN_DIR"
                exec ${pkgs.ags}/bin/ags run main.js
              '')
            ];

            # Custom layout design borders styles
            xdg.configFile."ags/style.css".text = ''
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
              .icon { font-size: 24px; color: #7aa2f7; }
              .label { font-size: 12px; margin-top: 4px; }
            '';
          })
        ];
      };
    };
}
