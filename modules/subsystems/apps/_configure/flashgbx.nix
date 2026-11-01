#
# GBX cart flashing. The tool is installed for the system; serial access
# (dialout) goes to the users that list the "flashgbx" feature.
#
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  flashgbxUsers = inputs.self.subsystems.identity.query.withFeature config.ltp.identity.facts.users "flashgbx";
in
{
  users.users = lib.mapAttrs (_: _: {
    extraGroups = [ "dialout" ];
  }) flashgbxUsers;

  environment.systemPackages = [ pkgs.flashgbx ];
}
