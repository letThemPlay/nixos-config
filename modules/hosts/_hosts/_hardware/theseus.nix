{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {

    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ "amdgpu" ];

      luks.devices."cryptroot".device = "/dev/disk/by-uuid/217f7d69-c493-4d56-a7b9-9aa28ae9abbc";
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/2fdd8587-2a50-471d-b43b-80a8ea83fbb2";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress=zstd"
      ];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/2fdd8587-2a50-471d-b43b-80a8ea83fbb2";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/2fdd8587-2a50-471d-b43b-80a8ea83fbb2";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd"
      ];
    };
    "/etc/nixos" = {
      device = "/dev/disk/by-uuid/2fdd8587-2a50-471d-b43b-80a8ea83fbb2";
      fsType = "btrfs";
      options = [
        "subvol=@nixos-config"
        "compress=zstd"
      ];
    };
    "/log" = {
      device = "/dev/disk/by-uuid/2fdd8587-2a50-471d-b43b-80a8ea83fbb2";
      fsType = "btrfs";
      options = [
        "subvol=@log"
        "compress=zstd"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5B67-D937";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
