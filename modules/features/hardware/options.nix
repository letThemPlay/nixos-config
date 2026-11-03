{ config, ... }:
let
  hardware = config.ltp.features.hardware;
in
{
  # Options only.
  flake.nixosModules.hardware-options =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.hardware = {

        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the hardware feature renders GPUs and the guest profile.";
        };

        gpus = mkOption {
          type = types.attrsOf hardware.types.gpu;
          default = { };

          example = {
            igpu = {
              vendor = "amd";
              integrated = true;
              busId = "PCI:6:0:0";
            };
            dgpu = {
              vendor = "nvidia";
              busId = "PCI:1:0:0";
            };
          };

          description = ''
            The host's GPUs. A host that declares none gets no graphics
            settings from this feature.
          '';
        };

        prime = mkOption {
          type = hardware.types.prime;
          default = "offload";
          description = ''
            PRIME mode for an nvidia GPU next to an integrated one:
            offload (dGPU on demand), sync (dGPU renders everything) or
            none.
          '';
        };

        audio.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the host has sound (PipeWire).";
        };

        bluetooth.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the host has Bluetooth (BlueZ, blueman).";
        };

        facts = {
          audio = mkOption {
            type = types.bool;
            readOnly = true;
            description = "Whether the host has sound; the desktop binds media keys only then.";
          };

          bluetooth = mkOption {
            type = types.bool;
            readOnly = true;
            description = "Whether the host has Bluetooth; the bar shows it only then.";
          };
        };

        guest = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "qemu";
          description = "Virtual machine guest type, or null on bare metal.";
        };

      };
    };
}
