_: {

  # Enabled services.<name>.enable.
  services = [
    "qemuGuest"
    "spice-vdagentd"
    "fstrim"
  ];

  initrdModules = [
    "ata_piix" # Intel IDE controllers
    "uhci_hcd" # USB controllers
    "virtio_pci" # VirtIO PCI bus
    "virtio_scsi" # VirtIO SCSI disks
    "sd_mod" # SCSI disks
    "sr_mod" # CD-ROM
  ];

  # Serial and virtual console, for the hypervisor's console view.
  kernelParams = [
    "console=ttyS0"
    "console=tty0"
  ];

}
