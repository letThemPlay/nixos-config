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
        # Group network settings to prevent Statix key duplication errors
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
            # 👑 THE HYPERVISOR-SAFE PACKAGE WRAPPER:
            # Compiles the menu into an absolute, path-native store package bin!
            home.packages = [
              (pkgs.writeShellScriptBin "control-center" ''
                #!/bin/sh

                # 1. Query general software state matrices (Safe on both Proxmox and Laptops!)
                # 'nmcli -t -f STATE general' returns 'connected', 'disconnected', or 'asleep' instantly [INDEX: 1.2.3, 1.3.5].
                NET_STATE=$(${pkgs.networkmanager}/bin/nmcli -t -f STATE general 2>/dev/null || echo "disconnected")

                # Query Bluetooth safely via a non-interactive pipe string layout
                BT_RAW=$(echo "show" | ${pkgs.bluez}/bin/bluetoothctl 2>/dev/null || echo "Powered: no")
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

                # 3. Present the selection matrix to Fuzzel via standard CPU rendering
                SELECTION=$(printf "%s\n%s\n    Suspend System\n    Power Off\n" "$NET_OPT" "$BT_OPT" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --render-mode=pixman --p "Control Center: " --width 25 --lines 4)

                # 4. Route commands straight to core system daemons
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
