#
# Switches display layouts as monitors come and go. It only runs where the host
# declares profiles (ltp.desktop.displays), as it has nothing to do otherwise.
#
{
  config,
  lib,
  ...
}:
let
  inherit (config.ltp.desktop) displays;

  settings = import ../../_adapters/kanshi.nix { inherit lib; } { inherit displays; };
in
{
  home-manager.sharedModules = lib.optional (displays.profiles != { }) (_: {
    services.kanshi = {
      enable = true;
      inherit settings;
    };
  });
}
