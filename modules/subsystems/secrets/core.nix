#
# The secrets core, laid out like the storage core:
#
#   _domain/    secret file and model types
#   _usecases/  normalize (declared secrets -> repository facts), validate
#   _adapters/  model -> agenix settings (plain data)
#
# The repository's secrets/ is core data: keys.nix (public keys by
# name), secrets.nix (agenix rules) and the encrypted files.
#
# api.nix and module.nix beside this file are the outer ring.
#
{ config, lib, ... }:
let
  inherit (config.flake.subsystems) diagnostics;
in
{
  flake.subsystems.secrets = lib.fix (secrets: {

    types = import ./_domain/types.nix { inherit lib; };

    dir = ../../../secrets;

    keys = import (secrets.dir + "/keys.nix");

    rules = import (secrets.dir + "/secrets.nix");

    normalize = import ./_usecases/normalize.nix { inherit lib secrets; };

    validate = import ./_usecases/validate.nix { inherit lib diagnostics; };

    agenix = import ./_adapters/agenix.nix { inherit lib; };

  });
}
