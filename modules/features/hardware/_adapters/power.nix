_:

#
# Power profiles (power-profiles-daemon) and the battery's levels (UPower),
# as plain NixOS settings. The alerts at those levels come from the desktop;
# the action at the last one comes from UPower, which runs without a session.
#
{ model }:

{
  profiles.active = model.powerProfiles;

  battery = {
    inherit (model.battery) active;

    upower = {
      enable = true;
      percentageLow = model.battery.lowAt;
      percentageCritical = model.battery.criticalAt;
      percentageAction = model.battery.actionAt;
      criticalPowerAction = model.battery.action;
    };
  };
}
