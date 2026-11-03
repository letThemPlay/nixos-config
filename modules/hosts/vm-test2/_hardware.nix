{
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [
        "uhci_hcd"
        "ehci_pci"
        "ahci"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [
        "virtio_gpu"
        "qxl"
      ];
    };

    kernelModules = [ ];
    extraModulePackages = [ ];
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
