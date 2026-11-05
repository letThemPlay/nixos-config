#
# The unified shell's Wi-Fi panel, in place of the backend's own window. It only
# knows how to reach iwd; with any other backend the shell has no command for it
# and the bar goes on opening networkUi.
#
{
  config,
  lib,
  pkgs,
  desktop,
  ...
}:
let
  instance = import ../../_ui/instance.nix;
in
{
  ltp.desktop = {
    binds."Mod+W" = instance.bind pkgs "wifi" "toggle";

    ui.commands = lib.optionalAttrs (config.ltp.network.facts.wireless == "iwd") {
      wifi = [ "${desktop.wifiHelper pkgs}" ];
    };
  };
}
