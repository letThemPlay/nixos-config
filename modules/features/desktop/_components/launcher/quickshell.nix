#
# The unified shell's launcher: a Spotlight-like search over applications,
# power actions and arithmetic. This bind replaces the launcher role's default.
#
{ pkgs, ... }:
let
  instance = import ../../_ui/instance.nix;
in
{
  ltp.desktop.binds."Mod+D" = instance.bind pkgs "launcher" "toggle";
}
