_: {
  flake.nixosModules.bluetooth =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.ltp.bluetooth;

      inherit (lib) mkIf mkEnableOption;
    in
    {
      options.ltp.bluetooth = {
        enable = mkEnableOption "Bluetooth hardware and Blueman manager support";
      };

      config = mkIf cfg.enable {
        services.blueman.enable = true;
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
      };
    };
}
