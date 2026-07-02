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

                # 1. Query live system hardware states natively
                WIFI_STATUS=$(${pkgs.networkmanager}/bin/nmcli radio wifi)
                BT_STATUS=$(${pkgs.bluez}/bin/bluetoothctl show | grep "Powered:" | awk '{print $2}')

                # 2. Formulate icon strings based on active interface metrics
                if [ "$WIFI_STATUS" = "enabled" ]; then WIFI_OPTION="    Disable Wi-Fi"; else WIFI_OPTION="    Enable Wi-Fi"; fi
                if [ "$BT_STATUS" = "yes" ]; then BT_OPTION="  Disable Bluetooth"; else BT_OPTION="    Enable Bluetooth"; fi

                # 👑 THE DEFINITIVE STREAM FIX:
                # We use printf to explicitly split choices into distinct line-break strings [INDEX: 1.3.4].
                # This breaks the input wait-lock, allowing Fuzzel to render its menu instantly! [INDEX: 1.3.2]
                SELECTION=$(printf "%s\n%s\n    Suspend System\n    Power Off\n" "$WIFI_OPTION" "$BT_OPTION" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --p "Control Center: " --width 25 --lines 4)

                # 3. Route selected macro changes straight to target hardware backends
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
