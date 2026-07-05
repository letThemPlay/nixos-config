_: {
  flake.nixosModules.bluetooth = _: {
    config = {
      services.blueman.enable = true;
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
    };
  };
}
