{ config, ... }:
{
  # QEMU/KVM test VM with the erase-on-boot storage layout.
  ltp.hosts.vm-test2 = {
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

    module = {
      imports = [
        config.flake.modules.nixos.spice-display
        ./_hardware.nix
      ];

      ltp.storage = {
        enable = true;
        disk = "/dev/vda";
      };
    };
  };
}
