#
# The hardware core, laid out like the storage core:
#
#   _domain/    entities: GPU, PRIME mode, model
#   _usecases/  normalize, query, validate
#   _adapters/  gpus/<vendor> and guests/<type> (registries); graphics
#
# api.nix and module.nix beside this file are the outer ring. Generated
# hardware files (nixos-generate-config) stay in hosts/_hosts/_hardware.
#
{ config, lib, ... }:
let
  inherit (config.flake.subsystems) diagnostics;
in
{
  flake.subsystems.hardware = lib.fix (hardware: {

    types = import ./_domain/types.nix { inherit lib; };

    normalize = import ./_usecases/normalize.nix { inherit lib hardware; };

    query = import ./_usecases/query.nix { inherit lib; };

    validate = import ./_usecases/validate.nix { inherit lib hardware diagnostics; };

    # GPU vendor registry: { driver; primeField; }.
    gpus = {
      amd = import ./_adapters/gpus/amd.nix { };
      intel = import ./_adapters/gpus/intel.nix { };
      nvidia = import ./_adapters/gpus/nvidia.nix { };
    };

    # Guest registry, keyed like ltp.hardware.guest:
    # { services; initrdModules; kernelParams; }.
    guests = {
      qemu = import ./_adapters/guests/qemu.nix { };
    };

    graphics = import ./_adapters/graphics.nix { inherit lib hardware; };

  });
}
