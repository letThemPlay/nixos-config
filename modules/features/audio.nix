_: {
  flake.nixosModules.audio =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.ltp.audio;
    in
    {
      options.ltp.audio = {
        pipewire = {
          enable = lib.mkEnableOption "PipeWire audio server framework" // {
            default = true;
          };
        };
      };

      config = lib.mkIf cfg.pipewire.enable {
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
        };
      };
    };
}
