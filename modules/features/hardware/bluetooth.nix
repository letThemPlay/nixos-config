_: {
  flake.nixosModules.bluetooth =
    { config, lib, ... }:
    {
      config = {
        services.blueman.enable = true;
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
        };

        # Paired devices and adapter settings.
        ohmydarlings.storage.persistence.state.directories = lib.mkIf config.ohmydarlings.storage.enable [
          "/var/lib/bluetooth"
        ];
      };
    };
}
