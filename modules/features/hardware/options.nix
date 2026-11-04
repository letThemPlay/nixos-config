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

        backlight.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the host has a screen backlight it can dim.";
        };

        powerProfiles.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether power profiles are managed (power-profiles-daemon).";
        };

        battery = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Whether the battery's levels and last-resort action are managed (UPower).";
          };

          lowAt = mkOption {
            type = types.ints.between 0 100;
            default = 20;
            description = "Percentage treated as low; the desktop warns here.";
          };

          criticalAt = mkOption {
            type = types.ints.between 0 100;
            default = 5;
            description = "Percentage treated as critical; the desktop warns again here.";
          };

          actionAt = mkOption {
            type = types.ints.between 0 100;
            default = 2;
            description = "Percentage at which criticalAction runs.";
          };

          criticalAction = mkOption {
            type = types.str;
            default = "PowerOff";
            example = "Hibernate";
            description = "What to do at actionAt: PowerOff, Hibernate or HybridSleep. The last two need swap.";
          };
        };

        facts = {
          powerProfiles = mkOption {
            type = types.bool;
            readOnly = true;
            description = "Whether power profiles are managed; the desktop offers a selector only then.";
          };

          battery = mkOption {
            type = types.bool;
            readOnly = true;
            description = "Whether the battery's levels are managed; the desktop warns at them only then.";
          };

          batteryLevels = mkOption {
            type = types.attrsOf types.int;
            readOnly = true;
            description = "The levels the desktop warns at: low and critical.";
          };

          backlight = mkOption {
            type = types.bool;
            readOnly = true;
            description = "Whether the host has a backlight; the desktop binds brightness keys only then.";
          };

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
