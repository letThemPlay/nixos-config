{ lib, hardware }:
let
  inherit (lib) attrValues filter;
in

#
# cfg is the ltp.hardware option set, or any attrset of the same shape.
# No module system is required.
#
cfg:

let
  gpus = attrValues cfg.gpus;

  hasNvidia = builtins.any (gpu: gpu.vendor == "nvidia") gpus;

  hasIntegrated = filter (gpu: gpu.integrated) gpus != [ ];
in
{
  inherit (cfg) gpus;

  prime = {
    mode = cfg.prime;

    active = cfg.prime != "none" && hasNvidia && hasIntegrated;
  };

  audio = cfg.audio.enable;

  bluetooth = cfg.bluetooth.enable;

  backlight = cfg.backlight.enable;

  guest = {
    name = cfg.guest;

    known = cfg.guest == null || hardware.guests ? ${cfg.guest};
  };
}
