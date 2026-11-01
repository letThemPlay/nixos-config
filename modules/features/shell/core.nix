#
# The shell core, laid out like the storage core:
#
#   _domain/    entities: user shell and model types; default aliases
#   _usecases/  normalize (aliases + identity facts -> model), validate
#   _adapters/  shells/<name> (registry)
#
# options.nix and module.nix beside this file are the outer ring. Features
# contribute shell-neutral aliases through ltp.shell.aliases.
#
{ config, lib, ... }:
let
  inherit (config.flake.features) diagnostics;
in
{
  flake.features.shell = lib.fix (shell: {

    types = import ./_domain/types.nix { inherit lib; };

    defaultAliases = import ./_domain/aliases.nix { };

    normalize = import ./_usecases/normalize.nix { inherit lib shell; };

    validate = import ./_usecases/validate.nix { inherit lib shell diagnostics; };

    #
    # Shell registry. The keys are the valid values of a user's shell.
    # An entry provides:
    #
    #   package : login shell package name in pkgs
    #   system  : { programs = [ names to enable system-wide ]; }
    #   render  : { aliases, pkgs } -> home-manager settings
    #
    shells = {
      bash = import ./_adapters/shells/bash.nix { };
      zsh = import ./_adapters/shells/zsh.nix { };
    };

  });
}
