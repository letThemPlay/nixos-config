#
# The unified shell's tunnel switcher: a panel listing the tunnels the network
# feature publishes (ltp.network.facts.tunnels), opened from the bar, the
# control center or Mod+Shift+W. The units do the work and systemd stops
# whatever a tunnel conflicts with, so the shell only starts, stops and asks;
# the network feature's polkit rule lets the user do that for these units
# alone.
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  instance = import ../../_ui/instance.nix;

  systemctl = action: [
    "${config.systemd.package}/bin/systemctl"
    action
  ];
in
{
  ltp.desktop = {
    # Beside Wi-Fi's Mod+W; only where there is something to switch.
    binds = lib.mkIf (config.ltp.network.facts.tunnels != { }) {
      "Mod+Shift+W" = instance.bind pkgs "tunnels" "toggle";
    };

    # Each takes the tunnels' unit names.
    ui.commands = {
      tunnelStatus = systemctl "is-active";
      tunnelStart = systemctl "start";
      tunnelStop = systemctl "stop";
    };
  };
}
