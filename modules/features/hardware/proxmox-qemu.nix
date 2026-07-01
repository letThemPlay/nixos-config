_: {
  flake.nixosModules.proxmox-qemu =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.ltp.hardware.proxmox-qemu;
    in
    {
      options.ltp.hardware.proxmox-qemu.enable =
        lib.mkEnableOption "Proxmox QEMU VM integration optimizations"
        // {
          default = false;
        };

      config = lib.mkIf cfg.enable {

        services = {
          qemuGuest.enable = true;
          spice-vdagentd.enable = true;
        };

        boot = {
          initrd.availableKernelModules = [
            "ata_piix" # Intel IDE controllers
            "uhci_hcd" # USB controllers
            "virtio_pci" # Fast VirtIO paravirtualized bus interface pipelines
            "virtio_scsi" # Optimized SCSI storage controllers layer
            "sd_mod" # SCSI disk mapping support
            "sr_mod" # CD-ROM mapping support
          ];

          kernelParams = [
            "console=ttyS0"
            "console=tty0"
          ];
        };

        services.fstrim.enable = true;
      };
    };
}
