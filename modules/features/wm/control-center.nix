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
            home.file.".local/bin/control-center" = {
              executable = true;

              text = ''
                #!/bin/sh

                WIFI_STATUS=$(${pkgs.networkmanager}/bin/nmcli radio wifi)
                BT_STATUS=$(${pkgs.bluez}/bin/bluetoothctl show | grep "Powered:" | awk '{print $2}')

                if [ "$WIFI_STATUS" = "enabled" ]; then WIFI_OPTION="    Disable Wi-Fi"; else WIFI_OPTION="    Enable Wi-Fi"; fi
                if [ "$BT_STATUS" = "yes" ]; then BT_OPTION="  Disable Bluetooth"; else BT_OPTION="    Enable Bluetooth"; fi

                SELECTION=$(printf "%s\n%s\n    Suspend System\n    Power Off" "$WIFI_OPTION" "$BT_OPTION" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --p "Control Center: " --width 25 --lines 4)

                case "$SELECTION" in
                    *Disable\ Wi-Fi*) ${pkgs.networkmanager}/bin/nmcli radio wifi off ;;
                    *Enable\ Wi-Fi*)  ${pkgs.networkmanager}/bin/nmcli radio wifi on ;;
                    *Disable\ Bluetooth*) ${pkgs.bluez}/bin/bluetoothctl power off ;;
                    *Enable\ Bluetooth*)  ${pkgs.bluez}/bin/bluetoothctl power on ;;
                    *Suspend*) systemctl suspend ;;
                    *Power\ Off*) systemctl poweroff ;;
                esac
              '';
            };
          })
        ];
      };
    };
}
