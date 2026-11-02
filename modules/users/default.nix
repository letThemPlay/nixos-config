{ config, findFilesWithExt, ... }:
{
  #
  # The user catalogue: each file in _users defines
  # ltp.identity.users.<file name>. Hosts enable the users they have.
  # A user's public OpenPGP keys are the .asc files in gpg/<user>/.
  #
  flake.nixosModules.users =
    { lib, ... }:
    {
      config.ltp.identity.users = lib.listToAttrs (
        map (
          file:
          let
            name = lib.removeSuffix ".nix" (baseNameOf file);
          in
          lib.nameValuePair name (
            lib.mkMerge [
              (import file)
              { gpg.keys = findFilesWithExt "asc" (../../gpg + "/${name}"); }
            ]
          )
        ) (findFilesWithExt "nix" ./_users)
      );
    };

  # Present on every host; the datasheet enables the users it has.
  flake.modules.nixos.features.imports = [ config.flake.nixosModules.users ];
}
