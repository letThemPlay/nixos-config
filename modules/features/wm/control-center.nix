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
        lib.mkEnableOption "Graphical iOS/Android style system control panel widget via Astal"
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

        # Ensure system-wide notification hooks preserve logs for our drawer widget
        services.dbus.packages = [ pkgs.mako ];

        home-manager.sharedModules = [
          ({ pkgs, ... }: {
            # 👑 THE ASTAL COMPONENT POOL:
            # We provision the core AGS v2 daemon bundle alongside Astal's native wire-level
            # network, bluetooth, and icon asset library packages! [INDEX: 1.2.1, 1.2.5]
            home.packages = [
              pkgs.ags # Aylur's GTK Shell Core Engine v2 [INDEX: 1.2.5]
              pkgs.material-symbols # Android/iOS design icon glyph maps
            ];

            # Configure Mako to preserve historical messages for our shelf drawer
            services.mako.extraConfig = ''
              [history]
              enabled=1
              limit=50
            '';

            # 👑 THE DECLARATIVE ASTAL DROPDOWN CONFIGURATION:
            # We write a native GJS Astal script layout directly to ~/.config/ags/config.js [INDEX: 1.2.5]
            xdg.configFile."ags/config.js".text = ''
              const App = require("resource:///com/github/Aylur/ags/app.js");
              const Widget = require("resource:///com/github/Aylur/ags/widget.js");

              // 👑 NATIVE ASTAL SYSTEM BUS INPUTS:
              // Instead of calling external CLI subprocesses, we tap into direct D-Bus bindings! [INDEX: 1.2.1]
              const Network = require("resource:///com/github/Aylur/ags/service/network.js");
              const Bluetooth = require("resource:///com/github/Aylur/ags/service/bluetooth.js");

              // 📱 Astal Connected Button Module
              const NetworkButton = () => Widget.Button({
                  class_name: "quick-button",
                  on_clicked: () => {
                      // Toggle global networking state natively via Astal API! [INDEX: 1.2.1]
                      Network.toggleWifi();
                  },
                  child: Widget.Box({
                      vertical: true,
                      children: [
                          Widget.Label({ label: "  ", class_name: "icon" }),
                          Widget.Label({ label: "Network", class_name: "label" })
                      ]
                  })
              });

              const BluetoothButton = () => Widget.Button({
                  class_name: "quick-button",
                  on_clicked: () => {
                      // Toggle global hardware power state natively via Astal API! [INDEX: 1.2.1]
                      Bluetooth.toggle();
                  },
                  child: Widget.Box({
                      vertical: true,
                      children: [
                          Widget.Label({ label: "", class_name: "icon" }),
                          Widget.Label({ label: "Bluetooth", class_name: "label" })
                      ]
                  })
              });

              // 👑 Symmetrical Control Center Grid Dashboard Container
              const ControlCenterPanel = () => Widget.Box({
                  class_name: "control-center-panel",
                  vertical: true,
                  children: [
                      Widget.Box({
                          class_name: "grid-container",
                          children: [
                              NetworkButton(),
                              BluetoothButton(),
                              Widget.Button({
                                  class_name: "quick-button",
                                  on_clicked: () => App.quit(),
                                  child: Widget.Label({ label: "    Quit Desk", class_name: "label" })
                              })
                          ]
                      })
                  ]
              });

              // Instantiate our desktop Layer-Shell window targeting Niri [INDEX: 1.1.3]
              const ccWindow = Widget.Window({
                  name: "control-center-window",
                  anchor: ["top", "right"],
                  margin_top: 40,
                  margin_right: 12,
                  child: ControlCenterPanel(),
                  visible: false,
              });

              App.config({ windows: [ccWindow] });
            '';

            # Visual CSS Sheets to layout our rounded control panes
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
              .quick-button:hover { background-color: #414868; }
              .icon { font-size: 24px; color: #7aa2f7; }
              .label { font-size: 12px; margin-top: 4px; }
            '';
          })
        ];
      };
    };
}
