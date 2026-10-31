#
# The storage library, one directory per Clean Architecture ring:
#
#   _domain/    entities: volume, persistence and layout types; layouts
#   _usecases/  normalize (host settings -> model), validate, query
#   _adapters/  model -> disko, rollback (per backend) and preservation
#
# The underscore directories are not flake-parts modules (import-tree
# skips them); each file is a plain function. `storage` is the
# assembled library itself, so the parts can refer to each other
# without global names.
#
{ config, lib, ... }:
let
  inherit (config.flake.library) diagnostics;
in
{
  flake.library.storage = lib.fix (storage: {

    types = import ./_domain/types.nix { inherit lib storage; };

    layouts = import ./_domain/layouts.nix { };

    normalize = import ./_usecases/normalize.nix { inherit lib storage; };

    query = import ./_usecases/query.nix { inherit lib; };

    validate = import ./_usecases/validate.nix { inherit lib storage diagnostics; };

    #
    # Backend registry. The keys are the valid values of
    # ltp.storage.filesystem.type; types.backend and validation
    # derive from them, and the storage module renders the selected one.
    #
    # A backend provides:
    #
    #   disko    : { model } -> { devices; rootDevice; }
    #   rollback : { model, rootDevice, pkgs, utils } -> { active; script; service; }
    #
    backends = {
      btrfs = import ./_adapters/btrfs { inherit lib storage; };
    };

    # Backend-agnostic adapter.
    preservation = import ./_adapters/preservation.nix { inherit lib; };

  });
}
