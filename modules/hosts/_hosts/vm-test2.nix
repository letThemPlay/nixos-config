{ inputs, ... }: {
  hostName = "vm-test2";
  architecture = "x86_64-linux";
  stateVersion = "26.05";

  bundles = [
    "base"
    "vm"
    "window-management"
    "core-apps"
  ];

  users = [ "kelvin" ];

  extraModules = [
    (inputs.self + "/modules/hosts/_hosts/_settings/vm-test.nix")
    (inputs.self + "/modules/hosts/_hosts/_settings/vm-test2.nix")
  ];
}
