#
# The identity core, laid out like the storage core:
#
#   _domain/    entities: user catalogue entry, normalized user, model
#   _usecases/  normalize (host settings + storage facts -> model),
#               query, validate
#   _adapters/  model -> accounts, ephemeral-root identity, home-manager
#
# api.nix, module.nix and home.nix beside this file are the outer ring.
#
# Each file is a plain function; `identity` is the assembled core.
#
{ config, lib, ... }:
let
  inherit (config.flake.subsystems) diagnostics;
in
{
  flake.subsystems.identity = lib.fix (identity: {

    types = import ./_domain/types.nix { inherit lib; };

    normalize = import ./_usecases/normalize.nix { inherit lib; };

    query = import ./_usecases/query.nix { inherit lib; };

    validate = import ./_usecases/validate.nix { inherit lib identity diagnostics; };

    accounts = import ./_adapters/accounts.nix { inherit lib; };

    ephemeral = import ./_adapters/ephemeral.nix { };

    home = import ./_adapters/home.nix { inherit lib; };

  });
}
