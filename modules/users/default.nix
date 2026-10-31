{ findFilesWithExt, ... }:
{
  #
  # The user catalogue: each file in _users defines
  # ltp.identity.users.<file name>. Hosts enable the users they have.
  #
  flake.nixosModules.users =
    { lib, ... }:
    {
      config.ltp.identity.users = lib.listToAttrs (
        map (file: lib.nameValuePair (lib.removeSuffix ".nix" (baseNameOf file)) (import file)) (
          findFilesWithExt "nix" ./_users
        )
      );
    };
}
