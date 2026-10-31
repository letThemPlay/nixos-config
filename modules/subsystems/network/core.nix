#
# The network core, laid out like the storage core:
#
#   _domain/    entities: link, profile and provider types; profiles;
#               DNS providers
#   _usecases/  normalize (host settings -> model), validate, query
#   _adapters/  model -> networkd units, resolved settings, iwd
#
# api.nix and module.nix beside this file are the outer ring.
#
# Each file is a plain function; `network` is the assembled core.
#
{ config, lib, ... }:
let
  inherit (config.flake.subsystems) diagnostics;
in
{
  flake.subsystems.network = lib.fix (network: {

    types = import ./_domain/types.nix { inherit lib network; };

    profiles = import ./_domain/profiles.nix { };

    providers = import ./_domain/providers.nix { };

    normalize = import ./_usecases/normalize.nix { inherit lib network; };

    query = import ./_usecases/query.nix { inherit lib; };

    validate = import ./_usecases/validate.nix { inherit lib network diagnostics; };

    #
    # Link backend registry. The keys are the valid values of
    # ltp.network.backend.
    #
    #   links : { model } -> { networks; }
    #
    backends = {
      networkd.links = import ./_adapters/networkd.nix { inherit lib network; };
    };

    #
    # Wireless backend registry, keyed like ltp.network.wireless.backend.
    #
    #   { model } -> { active; settings; state; }
    #
    wireless = {
      iwd = import ./_adapters/iwd.nix { inherit network; };
    };

    # Backend-agnostic resolver adapter.
    resolved = import ./_adapters/resolved.nix { };

  });
}
