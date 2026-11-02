{ config, ... }:
{
  # QEMU/KVM test VM without managed storage.
  ltp.hosts.vm-test = {
    system = "x86_64-linux";
    stateVersion = "26.05";

    # Kept from before per-host IDs; change only together with ZFS pools.
    hostId = "deadbeef";

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
