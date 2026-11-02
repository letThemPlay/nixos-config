{ config, ... }:
{
  # QEMU/KVM test VM without managed storage.
  flake.hosts.vm-test = {
    system = "x86_64-linux";
    stateVersion = "26.05";

    bundles = [
      "base"
      "vm"
      "window-management"
      "core-apps"
    ];

    users = [ "kelvin" ];

    module.imports = [
      config.flake.modules.nixos.spice-display
      ./_hardware.nix
    ];
  };
}
