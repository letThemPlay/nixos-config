{ inputs, findFilesWithExt, ... }: {
  flake.nixosModules.users =
    {
      lib,
      ...
    }:
    let
      inherit (inputs) self;

      userFiles = findFilesWithExt "nix" ./_users;
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
