{ inputs, ... }: {
  flake.nixosModules.users =
    {
      lib,
      ...
    }:
    let
      userLib = import "${inputs.self}/modules/_lib/users.nix" { inherit lib; };
      fsLib = import "${inputs.self}/modules/_lib/filesystem.nix" { inherit lib; };

      userFiles = fsLib.findFilesWithExt "nix" ./_users;
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
