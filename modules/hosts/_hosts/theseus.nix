{ inputs, ... }: {
  hostName = "theseus";
  architecture = "x86_64-linux";
  stateVersion = "22.11";

  features = [
    "base"
    "laptop"
    "ui"
    "core-apps"
  ];

  users = [ "kelvin" ];

  extraModules = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    (inputs.self + "/modules/hosts/_hosts/_settings/theseus.nix")
  ];

  tpmUnlock = true;
  secureBoot = true;
}
