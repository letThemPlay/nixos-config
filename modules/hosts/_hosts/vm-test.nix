{ inputs, ... }: {
  hostName = "vm-test";
  architecture = "x86_64-linux";
  stateVersion = "26.05";

  features = [
    "base"
    "vm"
    "ui"
    "core-apps"
  ];

  users = [ "kelvin" ];

  extraModules = [
    "${inputs.self}/modules/hosts/_hosts/_settings/vm-test.nix"
  ];
}
