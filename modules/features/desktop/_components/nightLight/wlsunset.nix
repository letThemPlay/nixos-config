#
# Warms the screen on a schedule (ltp.desktop.nightLight), through whichever
# gamma control the compositor offers. The quick settings tile stops and starts
# the unit, so turning it off lasts until the next login.
#
{
  config,
  pkgs,
  ...
}:
let
  inherit (config.ltp.desktop) nightLight;

  systemctl = action: [
    "${pkgs.systemd}/bin/systemctl"
    "--user"
    action
    "wlsunset.service"
  ];
in
{
  ltp.desktop.ui.commands = {
    nightLightStatus = systemctl "is-active";
    nightLightOn = systemctl "start";
    nightLightOff = systemctl "stop";
  };

  home-manager.sharedModules = [
    (_: {
      services.wlsunset = {
        enable = true;
        sunset = nightLight.from;
        sunrise = nightLight.until;
        temperature.night = nightLight.temperature;
      };
    })
  ];
}
