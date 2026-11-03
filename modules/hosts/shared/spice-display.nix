{
  # Sizes suited to a generic SPICE display, shared by the QEMU test VMs.
  flake.modules.nixos.spice-display.ltp.theme.appearance = {
    cursor.size = 24;
    fontSize = {
      terminal = 11;
      applications = 12;
      desktop = 10;
    };
  };
}
