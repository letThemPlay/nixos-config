#
# The unified shell's power menu. Its entries are the core's power actions.
#
{ pkgs, ... }:
let
  instance = import ../../_ui/instance.nix;
in
{
  ltp.desktop.binds."Mod+X" = instance.bind pkgs "power" "toggle";
}
