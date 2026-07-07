{ inputs, ... }: {
  hostName = "vm-test2";
  architecture = "x86_64-linux";
  stateVersion = "26.05";

  features = [
    "base"
    "vm"
    "window-management"
    "core-apps"
    "impermanence"
  ];

  users = [ "kelvin" ];

  extraModules = [
    inputs.disko.nixosModules.disko
    (inputs.self + "/disko/disko-btrfs.nix")
    (inputs.self + "/modules/hosts/_hosts/_settings/vm-test.nix")
  ];
}
