#
# The unified shell's calendar: a month view that drops down from the bar's clock.
#
{ pkgs, ... }:
let
  instance = import ../../_ui/instance.nix;
in
{
  ltp.desktop.binds."Mod+Shift+D" = instance.bind pkgs "calendar" "toggle";
}
