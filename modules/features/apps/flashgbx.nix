{ config, ... }:
let
  identity = config.flake.subsystems.identity;
in
{
  #
  # GBX cart flashing for the users that list the "flashgbx" feature.
  # Hosts that do not include this feature skip it for every user.
  #
  flake.nixosModules.flashgbx =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      flashgbxUsers = identity.query.withFeature config.ltp.identity.facts.users "flashgbx";
    in
    {
      config = lib.mkIf (flashgbxUsers != { }) {
        users.users = lib.mapAttrs (_: _: {
          extraGroups = [ "dialout" ];
        }) flashgbxUsers;

        environment.systemPackages = [ pkgs.flashgbx ];
      };
    };
}
