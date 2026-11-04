#
# The unified shell's level display, and the brightness keys that feed it.
# brightnessctl writes through logind, so the session needs no extra rights.
#
{ pkgs, ... }:
let
  instance = import ../../_ui/instance.nix;

  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl --class=backlight";

  # Takes a delta such as 5%-, stopping short of a black screen, then has the
  # shell show the new level. The floor is raw, so it comes from the device.
  change = pkgs.writeShellScript "ltp-brightness" ''
    max=$(${brightnessctl} max)
    ${brightnessctl} --quiet --min-value=$(( max / 100 )) set "$1"
    ${pkgs.quickshell}/bin/qs -c ${instance.name} ipc call osd brightness
  '';

  brightness = delta: {
    spawn = [
      "${change}"
      delta
    ];
    direct = true;
    requires = [ "backlight" ];
  };
in
{
  ltp.desktop = {
    binds = {
      "XF86MonBrightnessUp" = brightness "5%+";
      "XF86MonBrightnessDown" = brightness "5%-";
    };

    ui.commands.brightnessStatus = [
      "${pkgs.brightnessctl}/bin/brightnessctl"
      "--class=backlight"
      "--machine-readable"
      "info"
    ];
  };
}
