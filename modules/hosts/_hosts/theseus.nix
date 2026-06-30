{ inputs, ... }: {
  hostName = "theseus";
  architecture = "x86_64-linux";
  stateVersion = "22.11";
  isLaptop = true;

  features = [
    "gpg"
    "git"
    "nixvim"
    "wifi"
    "bluetooth"
    "tailscale"
    "secureboot"
    "tpm"
    "tailscale"
  ];

  users = [ "kelvin" ];

  extraModules = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
  ];
}
