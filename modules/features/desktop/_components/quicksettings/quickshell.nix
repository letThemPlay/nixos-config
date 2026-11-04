#
# The unified shell's quick settings: audio, brightness, power profile and the
# everyday toggles. Its brightness row comes with the osd role's commands.
#
{ pkgs, ... }:
let
  instance = import ../../_ui/instance.nix;
in
{
  ltp.desktop.binds."Mod+S" = instance.bind pkgs "quicksettings" "toggle";
}
