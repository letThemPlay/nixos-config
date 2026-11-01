#
# The locale core, laid out like the storage core:
#
#   _domain/    entities: console and session keyboards, model
#   _usecases/  normalize, validate (form only)
#   _adapters/  model -> NixOS settings (plain data)
#
# api.nix and module.nix beside this file are the outer ring. The
# desktop feature reads the session keyboard from ltp.locale.
#
{ config, lib, ... }:
let
  inherit (config.flake.features) diagnostics;
in
{
  flake.features.locale = {

    types = import ./_domain/types.nix { inherit lib; };

    normalize = import ./_usecases/normalize.nix { };

    validate = import ./_usecases/validate.nix { inherit lib diagnostics; };

    nixos = import ./_adapters/nixos.nix { };

  };
}
