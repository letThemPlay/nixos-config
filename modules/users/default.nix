{ inputs, ... }: {
  flake.nixosModules.users =
    {
      lib,
      ...
    }:
    let
      inherit (inputs) self;
      fsLib = import "${inputs.self}/modules/_lib/filesystem.nix" { inherit lib; };

      userFiles = fsLib.findFilesWithExt "nix" ./_users;
    in
    {
      imports = lib.forEach userFiles (
        file:
        let
          userData = import file;
        in
        self.factory.user userData
      );
    };
}
