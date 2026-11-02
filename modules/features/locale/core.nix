#
# The locale core, laid out like the storage core:
#
#   _domain/    entities: console and session keyboards, model
#   _usecases/  normalize, validate (form only)
#   _adapters/  model -> NixOS settings (plain data)
#
# options.nix and module.nix beside this file are the outer ring. The
# desktop feature reads the session keyboard from ltp.locale.
#
{ config, lib, ... }:
let
  inherit (config.ltp.features) diagnostics;
in
{
  ltp.features.locale = {

    types = import ./_domain/types.nix { inherit lib; };

    normalize = import ./_usecases/normalize.nix { };

    validate = import ./_usecases/validate.nix { inherit lib diagnostics; };

    nixos = import ./_adapters/nixos.nix { };

  };

  # Present on every host; bundles and host settings decide what it does.
  flake.modules.nixos.features.imports = [
    config.flake.nixosModules.locale-options
    config.flake.nixosModules.locale
  ];
}
