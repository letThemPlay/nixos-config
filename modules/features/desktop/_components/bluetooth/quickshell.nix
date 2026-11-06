#
# The unified shell's Bluetooth panel, in place of blueman's window. Devices that
# need a code to pair stay with blueman, behind the panel's link.
#
{ pkgs, ... }:
let
  instance = import ../../_ui/instance.nix;
in
{
  ltp.desktop.binds."Mod+B" = instance.bind pkgs "bluetooth" "toggle";
}
