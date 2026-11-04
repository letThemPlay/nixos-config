#
# Warnings as the battery runs down, at the levels ltp.hardware.battery sets.
# They go through whichever notifier the session runs; a machine with no battery
# never sends one.
#
{ pkgs, ... }:
{
  ltp.desktop.ui.commands.notify = [
    "${pkgs.libnotify}/bin/notify-send"
    "--app-name=Battery"
  ];
}
