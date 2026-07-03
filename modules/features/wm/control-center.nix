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
            home.packages = [
              pkgs.ags # Aylur's GTK Shell Core Engine v2 [INDEX: 1.2.5]
              pkgs.material-symbols # Android/iOS design icon glyph maps

              # 👑 THE DETERMINISTIC INTERPROSPECTIVE BUNDLE FIX:
              (pkgs.writeShellScriptBin "control-center" ''
                #!/bin/sh

                # 👑 LINK THE NIX STORE TYPELIBS:
                # We inject Astal's exact store paths directly into GObject Introspection.
                # This explicitly satisfies GJS, clearing the 'namespace not found' panic instantly! [INDEX: 1.1.1]
                export GI_TYPELIB_PATH="${pkgs.ags}/lib/girepository-1.0:${pkgs.glib.out}/lib/girepository-1.0:$GI_TYPELIB_PATH"
                export LD_LIBRARY_PATH="${pkgs.ags}/lib:${pkgs.glib.out}/lib:$LD_LIBRARY_PATH"

                # Set up our temporary, tracking-free configuration sandbox
                RUN_DIR="/tmp/ags-control-center-$USER"
                mkdir -p "$RUN_DIR"

                # 👑 THE PURE ASTAL V2 JAVASCRIPT LAYER:
                cat << 'EOF' > "$RUN_DIR/main.js"
                import pkg from "gi://Astal?version=3.0";
                import AstalGtk from "gi://AstalGtk?version=3.0";
                import Gtk from "gi://Gtk?version=3.0";

                // Native introspective connections straight to Linux hardware layers [INDEX: 2.3.2]
                import Network from "gi://AstalNetwork";
                import Bluetooth from "gi://AstalBluetooth";

                const QuickButton = (icon, label, callback) => new AstalGtk.Button({
                    className: "quick-button",
                    onClicked: callback,
                    child: new AstalGtk.Box({
                        vertical: true,
                        children: [
                            new AstalGtk.Label({ label: icon, className: "icon" }),
                            new AstalGtk.Label({ label: label, className: "label" })
                        ]
                    })
                });

                const ControlCenterPanel = () => new AstalGtk.Box({
                    className: "control-center-panel",
                    vertical: true,
                    children: [
                        new AstalGtk.Box({
                            className: "grid-container",
                            children: [
                                QuickButton("  ", "Network", () => {
                                    const nw = Network.get_default();
                                    if (nw && nw.wifi) nw.wifi.toggle();
                                }),
                                QuickButton("", "Bluetooth", () => {
                                    const bt = Bluetooth.get_default();
                                    if (bt) bt.toggle();
                                })
                            ]
                        })
                    ]
                });

                // Fire up our native standalone Astal layout instance [INDEX: 2.5.2]
                pkg.main({
                    requestHandler: (request, res) => res("Control Center Running"),
                    main: () => {
                        new AstalGtk.Window({
                            name: "control-center-window",
                            anchor: AstalGtk.WindowAnchor.TOP | AstalGtk.WindowAnchor.RIGHT,
                            marginTop: 40,
                            marginRight: 12,
                            child: ControlCenterPanel(),
                        });
                    }
                });
                EOF

                # Execute our application inside its local cache namespace [INDEX: 2.5.2]
                cd "$RUN_DIR"
                exec ${pkgs.ags}/bin/ags run main.js
              '')
            ];

            # Clean styling declarations
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
