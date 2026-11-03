#
# The identity core, laid out like the storage core:
#
#   _domain/    entities: user catalogue entry, normalized user, model
#   _usecases/  normalize (host settings + storage facts -> model),
#               query, validate
#   _adapters/  model -> accounts, ephemeral-root identity, home-manager,
#               OpenPGP (gpg, gpg-agent, ssh), user directories
#
# options.nix, module.nix and home.nix beside this file are the outer ring.
#
# Each file is a plain function; `identity` is the assembled core.
#
{ config, lib, ... }:
let
  inherit (config.ltp.features) diagnostics;
in
{
  ltp.features.identity = lib.fix (identity: {

    types = import ./_domain/types.nix { inherit lib; };

    normalize = import ./_usecases/normalize.nix { inherit lib identity; };

    query = import ./_usecases/query.nix { inherit lib; };

    validate = import ./_usecases/validate.nix { inherit lib identity diagnostics; };

    accounts = import ./_adapters/accounts.nix { inherit lib; };

    ephemeral = import ./_adapters/ephemeral.nix { };

    home = import ./_adapters/home.nix { inherit lib; };

    gpg = import ./_adapters/gpg.nix { inherit lib; };

    userDirs = import ./_adapters/user-dirs.nix { inherit lib; };

    #
    # Privilege escalation registry, keyed like ltp.identity.escalation.
    # Each key is a NixOS security.<key> program; the chosen one is
    # enabled and the others are turned off.
    #
    escalations = {
      sudo = { };
      sudo-rs = { };
    };

  });

  # Present on every host; bundles and host settings decide what it does.
  flake.modules.nixos.features.imports = [
    config.flake.nixosModules.identity-options
    config.flake.nixosModules.identity
    config.flake.nixosModules.identity-home
  ];
}
