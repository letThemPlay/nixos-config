{ inputs }:
let
  inherit (inputs) self;
  inherit (inputs.nixpkgs) lib;

  fsLib = import "${self}/modules/_lib/filesystem.nix" { inherit lib; };
in
{
  # Unified public key parsing logic
  importAscFiles =
    username:
    let
      ascFiles = fsLib.findFilesWithExt "asc" "${self}/gpg/${username}";
    in
    lib.forEach ascFiles (filePath: {
      source = filePath;
      trust = 5;
    });
}
