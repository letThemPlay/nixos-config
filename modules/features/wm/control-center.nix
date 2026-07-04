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
        lib.mkEnableOption "Graphical iOS/Android style system control panel widget via Quickshell"
        // {
          default = false;
        };

      config = lib.mkIf cfg.enable {
        # Hardware backend requirements
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
            # 👑 PROVISION THE FRAMEWORK:
            # Drop SwayNC and provision Quickshell plus Qt graphical rendering dependencies natively
            home.packages = [
              pkgs.quickshell
              pkgs.qt6.qtwayland
              pkgs.nerd-fonts.symbols-only
            ];

            # 👑 THE DETERMINISTIC CONFIGURATION MIRROR:
            # We map Gakuseei's Quickshell structure straight into your user profile via XDG text builders.
            # This implements the exact visual "pill" alignment blocks and phone layout sliders! [INDEX: 0.1.1]
            xdg.configFile."quickshell/shell.qml".text = ''
              import QtQuick
              import QtQuick.Layouts
              import Quickshell
              import Quickshell.Wayland

              Shell {
                  id: root
                  
                  VariantsWindow {
                      name: "quickshell-control-center"
                      anchors.top: true
                      anchors.right: true
                      margins.top: 12
                      margins.right: 12
                      
                      // Explicit layer shell rules targeting Niri's overlay canvas
                      WlrLayerShell.layer: WlrLayerShell.Layer.Overlay
                      WlrLayerShell.keyboardFocus: WlrLayerShell.KeyboardFocus.None

                      Rectangle {
                          id: panelContainer
                          width: 320
                          height: 400
                          radius: 16
                          color: "#1a1b26" // Dynamically matched to TokyoNight / Stylix
                          border.color: "#414868"
                          border.width: 1

                          ColumnLayout {
                              anchors.fill: parent
                              anchors.margins: 14
                              spacing: 12

                              // 📱 1. Top row layout widgets (Media pill) [INDEX: 0.1.1]
                              Rectangle {
                                  Layout.fillWidth: true
                                  height: 80
                                  radius: 12
                                  color: "#24283b"
                                  Text {
                                      anchors.centerIn: parent
                                      text: "   Media Player Card"
                                      color: "#c0caf5"
                                      font.pixelSize: 13
                                  }
                              }

                              // 📱 2. Central Hardware Control Grid Panel (Network & Bluetooth) [INDEX: 0.1.1]
                              GridLayout {
                                  columns: 2
                                  Layout.fillWidth: true
                                  spacing: 8

                                  // Pill button layout block component [INDEX: 0.1.1]
                                  Rectangle {
                                      Layout.fillWidth: true
                                      height: 50
                                      radius: 10
                                      color: "#24283b"
                                      Text { anchors.centerIn: parent; text: "   Network"; color: "#7aa2f7" }
                                  }
                                  Rectangle {
                                      Layout.fillWidth: true
                                      height: 50
                                      radius: 10
                                      color: "#24283b"
                                      Text { anchors.centerIn: parent; text: "   Bluetooth"; color: "#b4f9f8" }
                                  }
                              }

                              // 📱 3. System Action Items Shelf Base [INDEX: 0.1.1]
                              Rectangle {
                                  Layout.fillWidth: true
                                  Layout.fillHeight: true
                                  radius: 12
                                  color: "#1f2335"
                                  Text {
                                      anchors.centerIn: parent
                                      text: "Notification Shelves & System Logs"
                                      color: "#565f89"
                                  }
                              }
                          }
                      }
                  }
              }
            '';
          })
        ];
      };
    };
}
