#
# The unified shell's tunnel switcher: a tile per tunnel the network feature
# publishes (ltp.network.facts.tunnels), and a bar item while one is up. The
# units do the work and systemd stops whatever a tunnel conflicts with, so the
# shell only starts, stops and asks; the network feature's polkit rule lets
# the user do that for these units alone.
#
{ config, ... }:
let
  systemctl = action: [
    "${config.systemd.package}/bin/systemctl"
    action
  ];
in
{
  # Each takes the tunnels' unit names.
  ltp.desktop.ui.commands = {
    tunnelStatus = systemctl "is-active";
    tunnelStart = systemctl "start";
    tunnelStop = systemctl "stop";
  };
}
