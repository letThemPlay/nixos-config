{
  inputs,
  findFilesWithExt,
  ...
}:
{
  flake =
    { lib, ... }:
    let
      hostsDir = "${inputs.self}/modules/hosts/_hosts";
      hostFiles = findFilesWithExt "nix" hostsDir;
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
            value = inputs.self.factory.host hostData;
          }
        )
      );
    };
}
