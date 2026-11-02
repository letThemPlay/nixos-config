#
# The boot core, laid out like the storage core:
#
#   _domain/    entities: loader and model types
#   _usecases/  normalize (host settings + storage facts -> model),
#               validate
#   _adapters/  model -> systemd-boot, lanzaboote, TPM2 unlock
#
# options.nix and module.nix beside this file are the outer ring.
#
# Each file is a plain function; `boot` is the assembled core.
#
{ config, lib, ... }:
let
  inherit (config.ltp.features) diagnostics;
in
{
  ltp.features.boot = lib.fix (boot: {

    types = import ./_domain/types.nix { inherit lib; };

    normalize = import ./_usecases/normalize.nix { inherit boot; };

    validate = import ./_usecases/validate.nix { inherit lib boot diagnostics; };

    #
    # Loader registry. The keys are the valid values of ltp.boot.loader.
    #
    #   secureBoot : whether the loader signs boot files
    #   render     : { model } -> { settings; canTouchEfiVariables;
    #                               packages; state; }
    #
    loaders = {
      systemd-boot = {
        secureBoot = false;
        render = import ./_adapters/systemd-boot.nix { };
      };

      lanzaboote = {
        secureBoot = true;
        render = import ./_adapters/lanzaboote.nix { };
      };
    };

    # Loader-agnostic adapter.
    tpm = import ./_adapters/tpm.nix { };

  });

  # Present on every host; bundles and host settings decide what it does.
  flake.modules.nixos.features.imports = [
    config.flake.nixosModules.boot-options
    config.flake.nixosModules.boot
  ];
}
