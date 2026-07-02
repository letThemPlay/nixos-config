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
        lib.mkEnableOption "Fuzzel-driven system hardware control widget menu"
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
            home.packages = [
              (pkgs.writeShellScriptBin "control-center" ''
                #!/bin/sh

                # 👑 THE UNBLOCKING FIX: Avoid radio hardware polling inside virtualized environments!
                # Checking general network connectivity returns an instant text token without hanging.
                NET_CHECK=$(${pkgs.networkmanager}/bin/nmcli networking connectivity 2>/dev/null || echo "none")

                # Safe non-interactive bluetooth query string pass
                BT_RAW=$(echo "show" | ${pkgs.bluez}/bin/bluetoothctl 2>/dev/null || echo "Powered: no")
                BT_STATUS=$(echo "$BT_RAW" | grep "Powered:" | awk '{print $2}')

                # Translate text states safely into visual layout options
                if [ "$NET_CHECK" = "full" ] || [ "$NET_CHECK" = "limited" ]; then 
                    WIFI_OPTION="    Disconnect Network"
                else 
                    WIFI_OPTION="    Connect Network"
                fi

                if [ "$BT_STATUS" = "yes" ]; then 
                    BT_OPTION="  Disable Bluetooth"
                else 
                    BT_OPTION="    Enable Bluetooth"
                fi

                # Stream the choice array down into Fuzzel using standard CPU rendering
                SELECTION=$(printf "%s\n%s\n    Suspend System\n    Power Off\n" "$WIFI_OPTION" "$BT_OPTION" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --render-mode=pixman --p "Control Center: " --width 25 --lines 4)

                # Process toggles securely based on choice selection string tokens
                case "$SELECTION" in
                    *Disconnect*) ${pkgs.networkmanager}/bin/nmcli networking off ;;
                    *Connect*)    ${pkgs.networkmanager}/bin/nmcli networking on ;;
                    *Bluetooth\ off*|*Disable*) ${pkgs.bluez}/bin/bluetoothctl power off ;;
                    *Bluetooth\ on*|*Enable*)  ${pkgs.bluez}/bin/bluetoothctl power on ;;
                    *Suspend*) systemctl suspend ;;
                    *Power\ Off*) systemctl poweroff ;;
                esac
              '')
            ];
          })
        ];
      };
    };
}
