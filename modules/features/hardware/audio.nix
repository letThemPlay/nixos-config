_: {
  flake.nixosModules.audio =
    {
      pkgs,
      ...
    }:
    {
      config = {
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
