{ config, findFilesWithExt, ... }:
let
  inherit (config.flake) users;
in
{
  #
  # Renders the user catalogue (flake.users) on every host: the
  # identity data for ltp.identity, whose user type checks it, and each
  # user's home module for the users the host enables. A user's public
  # OpenPGP keys are the .asc files in modules/users/<name>/gpg/.
  #
  flake.nixosModules.users =
    { config, lib, ... }:
    let
      enabled = config.ltp.identity.facts.users;
    in
    {
      ltp.identity.users = lib.mapAttrs (
        name: user:
        removeAttrs user [ "home" ]
        // {
          gpg = (user.gpg or { }) // {
            keys = findFilesWithExt "asc" (./. + "/${name}/gpg");
          };
        }
      ) users;

      home-manager.users = lib.mapAttrs (_: user: { imports = [ user.home ]; }) (
        lib.filterAttrs (name: _: enabled ? ${name}) users
      );
    };

  # Present on every host; the datasheet enables the users it has.
  flake.modules.nixos.features.imports = [ config.flake.nixosModules.users ];
}
