#
# The nix core, laid out like the storage core:
#
#   _domain/    cache, gc and model types; default caches; the
#               experimental features this repository needs
#   _usecases/  normalize, validate
#   _adapters/  model -> nix settings (plain data)
#
# api.nix and module.nix beside this file are the outer ring.
#
{ config, lib, ... }:
let
  inherit (config.flake.subsystems) diagnostics;
in
{
  flake.subsystems.nix = lib.fix (nix: {

    types = import ./_domain/types.nix { inherit lib; };

    defaultCaches = import ./_domain/caches.nix { };

    requiredFeatures = import ./_domain/features.nix { };

    normalize = import ./_usecases/normalize.nix { inherit nix; };

    validate = import ./_usecases/validate.nix { inherit lib nix diagnostics; };

    settings = import ./_adapters/settings.nix { inherit lib; };

  });
}
