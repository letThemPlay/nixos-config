#
# The unified shell's top bar: two islands, left and right. The buttons for
# surfaces only exist where the shell draws those surfaces.
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  drawn = role: config.ltp.desktop.components.${role} == "quickshell";

  sessionApp =
    argv:
    [
      "uwsm"
      "app"
      "--"
    ]
    ++ argv;

  # The default route's link as one JSON line, polled by the shell.
  networkStatus = pkgs.writeShellScript "ltp-network-status" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.gawk
        pkgs.iproute2
        pkgs.iw
        pkgs.jq
      ]
    }

    link=$(ip -j route show default | jq -r '.[0].dev // empty')

    if [ -z "$link" ]; then
      echo '{"kind":"none","name":"","strength":0}'
    elif [ -d "/sys/class/net/$link/wireless" ]; then
      info=$(iw dev "$link" link)
      ssid=$(awk -F': ' '/SSID/ { print $2 }' <<< "$info")
      signal=$(awk '/signal/ { print $2 }' <<< "$info")

      # -90 dBm is barely usable and -50 dBm is as good as it gets.
      strength=$(( (''${signal:--90} + 90) * 100 / 40 ))
      strength=$(( strength < 0 ? 0 : strength > 100 ? 100 : strength ))

      jq -cn --arg name "$ssid" --argjson strength "$strength" \
        '{ kind: "wifi", name: $name, strength: $strength }'
    else
      jq -cn --arg name "$link" '{ kind: "wired", name: $name, strength: 100 }'
    fi
  '';
in
{
  # Battery state for the bar.
  services.upower.enable = true;

  ltp.desktop = {
    bar = {
      left =
        lib.optional (drawn "launcher") "launcher"
        ++ lib.optional (drawn "notifier") "notifications"
        ++ [
          "workspaces"
          "window"
        ];

      right = [
        "tray"
        "media"
        "network"
        "bluetooth"
        "volume"
        "battery"
        "clock"
      ]
      ++ lib.optional (drawn "quicksettings") "settings"
      ++ lib.optional (drawn "power") "power";

      requires = {
        bluetooth = [ "bluetooth" ];
        volume = [ "audio" ];
      };
    };

    ui.commands = {
      networkStatus = [ "${networkStatus}" ];
      networkUi = sessionApp [ "${pkgs.iwgtk}/bin/iwgtk" ];
      bluetoothUi = sessionApp [ "blueman-manager" ];
    };
  };
}
