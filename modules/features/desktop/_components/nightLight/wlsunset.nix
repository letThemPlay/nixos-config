#
# Warms the screen on a schedule (ltp.desktop.nightLight), through whichever
# gamma control the compositor offers.
#
# The quick settings tile says whether the screen is warm now, so it has to work
# by day too, when the schedule is holding the neutral temperature. wlsunset's own
# override is a signal that cycles modes it can't report, so warming on demand is a
# second instance with no daytime to return to. Only one client can hold an
# output's gamma, so the two units conflict.
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ltp.desktop) nightLight;

  schedule = "wlsunset.service";
  warm = "wlsunset-warm.service";

  systemctl =
    action: units:
    [
      "${pkgs.systemd}/bin/systemctl"
      "--user"
      action
    ]
    ++ units;
in
{
  ltp.desktop.ui.commands = {
    nightLightStatus = systemctl "is-active" [
      warm
      schedule
    ];
    nightLightWarm = systemctl "start" [ warm ];
    nightLightSchedule = systemctl "start" [ schedule ];
    nightLightOff = systemctl "stop" [
      warm
      schedule
    ];
  };

  home-manager.sharedModules = [
    (_: {
      services.wlsunset = {
        enable = true;
        sunset = nightLight.from;
        sunrise = nightLight.until;
        temperature.night = nightLight.temperature;
      };

      # wlsunset needs its day above its night, so a kelvin apart is as good as none.
      systemd.user.services.wlsunset-warm = {
        Unit = {
          Description = "Warm the screen now, outside the night light schedule";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
          Conflicts = [ schedule ];
        };

        Service.ExecStart = lib.concatStringsSep " " [
          "${pkgs.wlsunset}/bin/wlsunset"
          "-t ${toString nightLight.temperature}"
          "-T ${toString (nightLight.temperature + 1)}"
          "-S ${nightLight.until}"
          "-s ${nightLight.from}"
        ];
      };
    })
  ];
}
