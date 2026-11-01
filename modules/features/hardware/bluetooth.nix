_: {
  # Bluetooth through BlueZ and blueman; see ltp.hardware.bluetooth.
  flake.nixosModules.bluetooth = _: {
    ltp.hardware.bluetooth.enable = true;
  };
}
