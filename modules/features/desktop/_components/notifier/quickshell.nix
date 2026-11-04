#
# The unified shell's notification daemon and center. Both enter from the left
# screen edge, which niri's horizontally scrolling columns leave clear.
#
{ pkgs, ... }:
let
  instance = import ../../_ui/instance.nix;
in
{
  ltp.desktop.binds = {
    "Mod+N" = instance.bind pkgs "notifications" "toggle";
    "Mod+Escape" = instance.bind pkgs "notifications" "dismiss";
    "Mod+Shift+Escape" = instance.bind pkgs "notifications" "clear";
  };
}
