#
# The unified shell's notification daemon, with its notifications in the control
# center and its popups entering from the left screen edge, which niri's
# horizontally scrolling columns leave clear.
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  instance = import ../../_ui/instance.nix;
in
{
  ltp.desktop.binds = {
    "Mod+Escape" = instance.bind pkgs "notifications" "dismiss";
    "Mod+Shift+Escape" = instance.bind pkgs "notifications" "clear";

    # Quick settings opens the control center where there are both, so this only
    # covers a control center of notifications alone.
    "Mod+S" = lib.mkIf (config.ltp.desktop.components.quicksettings != "quickshell") (
      instance.bind pkgs "controlcenter" "toggle"
    );
  };
}
