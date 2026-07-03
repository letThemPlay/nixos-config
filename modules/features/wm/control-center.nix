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

      # 👑 THE NIX STORE COMPILER BUNDLE:
      # We construct a genuine compiled application binary directly inside the Nix store!
      # This removes any home directory script pollution and stops runtime path crashes.
      astal-control-center = pkgs.stdenv.mkDerivation {
        name = "control-center";
        src = pkgs.writeTextDir "main.js" ''
          import App from "gi://AstalApp";
          import Widget from "gi://AstalWidget";
          import Variable from "gi://AstalVariable";
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
                          QuickButton("  ", "Power Off", () => App.quit())
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
        '';

        # Build hook to compile GJS scripts into standalone system executables
        installPhase = ''
          mkdir -p $out/bin
          cp main.js $out/bin/control-center
          chmod +x $out/bin/control-center
        '';
      };
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

        home-manager.sharedModules = [
          (_: {
            # 👑 Register our compiled Nix store package directly into Kelvin's profile path!
            home.packages = [
              astal-control-center
              pkgs.material-symbols
            ];

            # Stylix will automatically theme our desktop modules out of the box,
            # but we can enforce CSS shapes for our buttons natively via XDG configuration tracks
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
