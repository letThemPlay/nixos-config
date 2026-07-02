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
            # 👑 Your script layout lives embedded natively inside this local store binary! [INDEX: 1.2.3]
            home.packages = [
              (pkgs.writeShellScriptBin "control-center" ''
                #!/bin/sh
                WIFI_STATUS=$(${pkgs.networkmanager}/bin/nmcli radio wifi)
                BT_STATUS=$(${pkgs.bluez}/bin/bluetoothctl show | grep "Powered:" | awk '{print $2}')

                if [ "$WIFI_STATUS" = "enabled" ]; then WIFI_OPTION="    Disable Wi-Fi"; else WIFI_OPTION="    Enable Wi-Fi"; fi
                if [ "$BT_STATUS" = "yes" ]; then BT_OPTION="  Disable Bluetooth"; else BT_OPTION="    Enable Bluetooth"; fi

                # 👑 Group options into a clean string layout to preserve data streams under systemd scopes
                MENU_OPTIONS=$(echo "$WIFI_OPTION\n$BT_STATUS\n    Suspend System\n    Power Off")

                SELECTION=$(echo "$MENU_OPTIONS" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --p "Control Center: " --width 25 --lines 4)

                case "$SELECTION" in
                    *Disable\ Wi-Fi*) ${pkgs.networkmanager}/bin/nmcli radio wifi off ;;
                    *Enable\ Wi-Fi*)  ${pkgs.networkmanager}/bin/nmcli radio wifi on ;;
                    *Disable\ Bluetooth*) ${pkgs.bluez}/bin/bluetoothctl power off ;;
                    *Enable\ Bluetooth*)  ${pkgs.bluez}/bin/bluetoothctl power on ;;
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
