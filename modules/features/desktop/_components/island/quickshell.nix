#
# The unified shell's center island: the clock when idle, growing to show what's
# happening, and expanding into a card when pressed. The bar gives it the clock,
# media and recording, and it takes ordinary notifications and levels too, except
# over a fullscreen window, which hides the bar.
#
{ pkgs, ... }:
let
  instance = import ../../_ui/instance.nix;
in
{
  ltp.desktop.binds."Mod+I" = instance.bind pkgs "island" "toggle";
}
