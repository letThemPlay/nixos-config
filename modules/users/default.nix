{ inputs, ... }: {
  flake.nixosModules.users =
    {
      lib,
      ...
    }:
    let
      userLib = import "${inputs.self}/modules/_lib/users.nix" { inherit lib; };

      usersDir = ./_users;

      userFiles = lib.mapAttrsToList (name: _: usersDir + "/${name}") (
        lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
          builtins.readDir usersDir
        )
      );
    in
    {
      options.users.profiles.enable = lib.mkEnableOption "Unified User Management Engine" // {
        default = true;
      };

      imports = lib.forEach userFiles (
        file:
        let
          userData = import file;
        in
        userLib.mkUser userData
      );
    };
}
