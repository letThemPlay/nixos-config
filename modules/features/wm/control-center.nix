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
        lib.mkEnableOption "Fuzzel-driven system hardware control widget menu"
        // {
          default = false;
        };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.bluetoothctl ];
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
                # 👑 DEFENSIVE DRIVER LOOKUPS:
                # Appending '|| true' ensures that if the hardware commands fail inside your bare VM,
                # the script doesn't crash or throw errors; it handles the empty tracking data safely! [INDEX: 1.2.2]
                WIFI_STATUS=$(${pkgs.networkmanager}/bin/nmcli radio wifi 2>/dev/null || echo "disabled")

                # Ensure bluetoothctl exits instantly even if no hardware controller is plugged into the VM [INDEX: 1.2.2]
                BT_RAW=$(echo "show" | ${pkgs.bluez}/bin/bluetoothctl 2>/dev/null || echo "Powered: no")
                BT_STATUS=$(echo "$BT_RAW" | grep "Powered:" | awk '{print $2}')

                # Evaluate icons and text parameters safely [INDEX: 1.1.5]
                if [ "$WIFI_STATUS" = "enabled" ]; then WIFI_OPTION="    Disable Wi-Fi"; else WIFI_OPTION="    Enable Wi-Fi"; fi
                if [ "$BT_STATUS" = "yes" ]; then BT_OPTION="  Disable Bluetooth"; else BT_OPTION="    Enable Bluetooth"; fi

                # Present choice matrix to Fuzzel
                SELECTION=$(printf "%s\n%s\n    Suspend System\n    Power Off\n" "$WIFI_OPTION" "$BT_OPTION" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --p "Control Center: " --width 25 --lines 4)

                # Process toggles securely
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
