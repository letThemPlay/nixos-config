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

                # 1. Fetch live network states cleanly
                NET_STATE=$(${pkgs.networkmanager}/bin/nmcli -t -f STATE general 2>/dev/null || echo "disconnected")

                # 👑 THE BLUETOOTH UNBLOCK: Use standard timeout commands inside the subshell expression!
                # If bluetoothd hangs on Proxmox, timeout forces an exit in 1s, falling back safely to 'no'.
                BT_RAW=$(timeout 1s sh -c "echo 'show' | ${pkgs.bluez}/bin/bluetoothctl" 2>/dev/null || echo "Powered: no")
                BT_STATE=$(echo "$BT_RAW" | grep "Powered:" | awk '{print $2}')

                # 2. Formulate icon choices based on text tokens
                if [ "$NET_STATE" = "connected" ]; then
                    NET_OPT="    Disable Networking"
                else
                    NET_OPT="    Enable Networking"
                fi

                if [ "$BT_STATE" = "yes" ]; then
                    BT_OPT="  Disable Bluetooth"
                else
                    BT_OPT="    Enable Bluetooth"
                fi

                # 👑 THE FUZZEL OPTION FIX: Changed '--p' to '--prompt' to pass validation checks! [INDEX: 1.3.1]
                SELECTION=$(printf "%s\n%s\n    Suspend System\n    Power Off\n" "$NET_OPT" "$BT_OPT" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --render-mode=pixman --prompt "Control Center: " --width 25 --lines 4)

                # 3. Route selected commands straight to system backends
                case "$SELECTION" in
                    *Disable\ Networking*) ${pkgs.networkmanager}/bin/nmcli networking off ;;
                    *Enable\ Networking*)  ${pkgs.networkmanager}/bin/nmcli networking on ;;
                    *Disable\ Bluetooth*)  ${pkgs.bluez}/bin/bluetoothctl power off ;;
                    *Enable\ Bluetooth*)   ${pkgs.bluez}/bin/bluetoothctl power on ;;
                    *Suspend*)            systemctl suspend ;;
                    *Power\ Off*)          systemctl poweroff ;;
                esac
              '')
            ];
          })
        ];
      };
    };
}
