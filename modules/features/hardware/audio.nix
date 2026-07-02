_: {
  flake.nixosModules.audio =
    {
      config,
      lib,
      pkgs,
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
        environment.systemPackages = [ pkgs.playerctl ];
        services.pulseaudio.enable = false;
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
