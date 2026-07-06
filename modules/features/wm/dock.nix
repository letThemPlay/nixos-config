_: {
  flake.nixosModules.dock = { pkgs, ... }: {
    home-manager.sharedModules = [
      ({ config, ... }: {
        home.packages = [ pkgs.nwg-dock-hyprland ];

        xdg.configFile."nwg-dock/config.json".text = builtins.toJSON {
          alignment = "center";
          position = "bottom";
          layer = "overlay";
          output = "";
          icon-size = 32;
          margin-bottom = 8;
          autohide = true;
          full-width = false;
        };

        xdg.configFile."nwg-dock/style.css".text = ''
          window {
              background: rgba(0, 0, 0, 0); /* Pure transparency on the root frame layer */
          }

          /* 📱 MAIN FLOATING ISLAND BOX CHASSIS */
          #box {
              /* Links straight to your active Stylix Base01 background with your 0.85 opacity! [INDEX: 1.1.6] */
              background-color: alpha(#${config.lib.stylix.colors.base01}, 0.85);
              border: 1px solid #${config.lib.stylix.colors.base03};
              border-radius: 16px;
              padding: 6px 12px;
              box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
          }

          /* Individual App Launcher Buttons */
          button {
              background: transparent;
              border: none;
              padding: 4px;
              margin: 2px 6px;
              border-radius: 8px;
              transition: all 0.15s ease-in-out;
          }

          /* Clean, high-utility interactive hover indicator state [INDEX: 1.1.6] */
          button:hover {
              background-color: alpha(#${config.lib.stylix.colors.base02}, 0.6);
              transform: scale(1.15) translateY(-4px); /* Modern floating pop-out transition effect! */
          }

          /* Active Running Applications Indicator Dot */
          button:checked {
              border-bottom: 2px solid #${config.lib.stylix.colors.base0D}; /* Highlights active apps in Function Blue! */
          }
        '';
      })
    ];
  };
}
