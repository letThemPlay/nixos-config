#
# The network core, laid out like the storage core:
#
#   _domain/    entities: link, profile and provider types; profiles;
#               DNS providers
#   _usecases/  normalize (host settings -> model), validate, query
#   _adapters/  model -> networkd units, resolved settings, iwd,
#               tailscale tunnels
#
# options.nix and module.nix beside this file are the outer ring.
#
# Each file is a plain function; `network` is the assembled core.
#
{ config, lib, ... }:
let
  inherit (config.ltp.features) diagnostics overrides;
in
{
  ltp.features.network = lib.fix (network: {

    types = import ./_domain/types.nix { inherit lib overrides; };

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
    #   { model } -> { active; settings; state; ui; }
    #
    wireless = {
      iwd = import ./_adapters/iwd.nix { inherit network; };
    };

    #
    # Tunnel backend registry, keyed like ltp.network.tunnels.<name>.backend.
    #
    #   { model; secretPath } -> { active; daemon; secrets; packages;
    #                             after; online; commands; state; }
    #
    # commands.<tunnel> = { start; stop; } are the argv lists the
    # tunnel's unit runs; secretPath maps an ltp.secrets name to its
    # runtime path.
    #
    tunnels = {
      tailscale = import ./_adapters/tailscale.nix { inherit lib; };
    };

    # Backend-agnostic resolver adapter.
    resolved = import ./_adapters/resolved.nix { };

  });

  # Present on every host; bundles and host settings decide what it does.
  flake.modules.nixos.features.imports = [
    config.flake.nixosModules.network-options
    config.flake.nixosModules.network
  ];
}
