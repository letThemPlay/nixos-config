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

                WIFI_STATUS=$(${pkgs.networkmanager}/bin/nmcli radio wifi 2>/dev/null || echo "disabled")
                BT_RAW=$(echo "show" | ${pkgs.bluez}/bin/bluetoothctl 2>/dev/null || echo "Powered: no")
                BT_STATUS=$(echo "$BT_RAW" | grep "Powered:" | awk '{print $2}')

                if [ "$WIFI_STATUS" = "enabled" ]; then WIFI_OPTION="    Disable Wi-Fi"; else WIFI_OPTION="    Enable Wi-Fi"; fi
                if [ "$BT_STATUS" = "yes" ]; then BT_OPTION="  Disable Bluetooth"; else BT_OPTION="    Enable Bluetooth"; fi

                # 👑 THE SOFTWARE RENDERING FIX:
                # Adding '--render-mode=pixman' instructs Fuzzel to skip GPU hardware pipeline scans! [INDEX: 1.1.2]
                # This breaks the infinite loop lock inside your Proxmox VM, forcing it to draw instantly.
                SELECTION=$(printf "%s\n%s\n    Suspend System\n    Power Off\n" "$WIFI_OPTION" "$BT_OPTION" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --render-mode=pixman --p "Control Center: " --width 25 --lines 4)

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
