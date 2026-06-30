{ inputs, ... }: {
  flake =
    { lib, ... }:
    let
      fsLib = import "${inputs.self}/modules/_lib/filesystem.nix" { inherit lib; };

      hostLib = import "${inputs.self}/modules/_lib/hosts.nix" { inherit inputs lib; };

      hostsDir = "${inputs.self}/modules/hosts/_hosts";

      hostFiles = fsLib.findFilesWithExt "nix" hostsDir;
    in
    {
      nixosConfigurations = lib.listToAttrs (
        lib.forEach hostFiles (
          file:
          let
            hostData = import file { inherit inputs; };
          in
          {
            name = hostData.hostName;
            value = hostLib.mkHost hostData;
          }
        )
      );
    };
}
