_: {
  #
  # Runs the host as a QEMU/KVM guest (e.g. on Proxmox): guest agent,
  # SPICE, virtio initrd modules and a serial console.
  #
  flake.nixosModules.qemu-guest = _: {
    ltp.hardware.guest = "qemu";
  };
}
