_:

#
# PipeWire with ALSA (including 32-bit), PulseAudio compatibility and
# WirePlumber, as plain NixOS settings. Media keys come from the desktop.
#
{ model }:

{
  active = model.audio;

  pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    wireplumber.enable = true;
  };
}
