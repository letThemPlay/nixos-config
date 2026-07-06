_: {
  flake.nixosModules.dock = { pkgs, ... }: {
    home-manager.sharedModules = [
      ({ config, ... }: {
        home.packages = [ pkgs.nwg-dock ];

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
              background: rgba(0, 0, 0, 0); 
          }

          #box {
              background-color: alpha(#${config.lib.stylix.colors.base01}, 0.85);
              border: 1px solid #${config.lib.stylix.colors.base03};
              border-radius: 16px;
              padding: 6px 12px;
              box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
          }

          button {
              background: transparent;
              border: none;
              padding: 4px;
              margin: 2px 6px;
              border-radius: 8px;
              transition: all 0.15s ease-in-out;
          }

          button:hover {
              background-color: alpha(#${config.lib.stylix.colors.base02}, 0.6);
              transform: scale(1.15) translateY(-4px); 
          }

          button:checked {
              border-bottom: 2px solid #${config.lib.stylix.colors.base0D}; 
          }
        '';
      })
    ];
  };
}
