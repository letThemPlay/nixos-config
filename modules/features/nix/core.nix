#
# The nix core, laid out like the storage core:
#
#   _domain/    cache, gc, ld and model types; default caches and
#               nix-ld libraries; the experimental features this
#               repository needs
#   _usecases/  normalize, validate
#   _adapters/  nix-conf: model -> nix.conf, gc and nix-ld settings
#               (plain data)
#
# options.nix and module.nix beside this file are the outer ring.
#
{ config, lib, ... }:
let
  inherit (config.ltp.features) diagnostics;
in
{
  ltp.features.nix = lib.fix (nix: {

    types = import ./_domain/types.nix { inherit lib; };

    defaultCaches = import ./_domain/caches.nix { };

    defaultLdLibraries = import ./_domain/ld-libraries.nix { };

    requiredFeatures = import ./_domain/required-features.nix { };

    normalize = import ./_usecases/normalize.nix { inherit lib nix; };

    validate = import ./_usecases/validate.nix { inherit lib nix diagnostics; };

    nixConf = import ./_adapters/nix-conf.nix { inherit lib; };

  });

  # Present on every host; bundles and host settings decide what it does.
  flake.modules.nixos.features.imports = [
    config.flake.nixosModules.nix-options
    config.flake.nixosModules.nix
  ];
}
