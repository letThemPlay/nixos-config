#
# The hardware core, laid out like the storage core:
#
#   _domain/    entities: GPU, PRIME mode, model
#   _usecases/  normalize, query, validate
#   _adapters/  gpu-vendors/<vendor> and guests/<type> (registries);
#               graphics, audio, bluetooth
#
# options.nix and module.nix beside this file are the outer ring. Generated
# hardware files (nixos-generate-config) stay in hosts/<name>/_hardware.nix.
#
{ config, lib, ... }:
let
  inherit (config.ltp.features) diagnostics;
in
{
  ltp.features.hardware = lib.fix (hardware: {

    types = import ./_domain/types.nix { inherit lib; };

    normalize = import ./_usecases/normalize.nix { inherit lib hardware; };

    query = import ./_usecases/query.nix { inherit lib; };

    validate = import ./_usecases/validate.nix { inherit lib hardware diagnostics; };

    # GPU vendor registry, keyed like ltp.hardware.gpus.<n>.vendor:
    # { driver; primeField; }.
    gpuVendors = {
      amd = import ./_adapters/gpu-vendors/amd.nix { };
      intel = import ./_adapters/gpu-vendors/intel.nix { };
      nvidia = import ./_adapters/gpu-vendors/nvidia.nix { };
    };

    # Guest registry, keyed like ltp.hardware.guest:
    # { services; initrdModules; kernelParams; }.
    guests = {
      qemu = import ./_adapters/guests/qemu.nix { };
    };

    graphics = import ./_adapters/graphics.nix { inherit lib hardware; };

    audio = import ./_adapters/audio.nix { };

    bluetooth = import ./_adapters/bluetooth.nix { };

  });

  # Present on every host; bundles and host settings decide what it does.
  flake.modules.nixos.features.imports = [
    config.flake.nixosModules.hardware-options
    config.flake.nixosModules.hardware
  ];
}
