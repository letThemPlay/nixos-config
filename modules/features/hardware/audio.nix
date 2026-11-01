_: {
  # Sound through PipeWire; see ltp.hardware.audio.
  flake.nixosModules.audio = _: {
    ltp.hardware.audio.enable = true;
  };
}
