{ config, ... }:
let
  hardware = config.flake.subsystems.hardware;
in
{
  # Options only.
  flake.nixosModules.hardware-api =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.hardware = {

        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the hardware subsystem renders GPUs and the guest profile.";
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
            settings from this subsystem.
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

        guest = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "qemu";
          description = "Virtual machine guest type, or null on bare metal.";
        };

      };
    };
}
