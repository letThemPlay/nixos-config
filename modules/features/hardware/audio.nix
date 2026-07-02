_: {
  flake.nixosModules.audio =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.features.hardware.audio;
    in
    {
      options.features.hardware.audio.enable = lib.mkEnableOption "PipeWire sound subsystem" // {
        default = true;
      };

      config = lib.mkIf cfg.enable {
        hardware.pulseaudio.enable = false;
        security.rtkit.enable = true;

        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;

          wireplumber.enable = true;
        };
      };
    };
}
