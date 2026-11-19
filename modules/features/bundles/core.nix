#
# The bundles core, laid out like the apps core:
#
#   _domain/     the catalogue (description, requires) and model types
#   _usecases/   normalize (selection -> active bundles through
#                requires), validate
#   _configure/  each bundle's settings, by catalogue name (module
#                functions, enabled while the bundle is active)
#
# options.nix and module.nix beside this file are the outer ring. A
# bundle only sets other features' options; every feature is present
# on every host. Identity reads the bundle names from ltp.bundles.facts.
#
{ config, lib, ... }:
let
  inherit (config.ltp.features) diagnostics;
in
{
  ltp.features.bundles = lib.fix (bundles: {

    types = import ./_domain/types.nix { inherit lib; };

    catalog = import ./_domain/catalog.nix { };

    normalize = import ./_usecases/normalize.nix { inherit lib bundles; };

    validate = import ./_usecases/validate.nix { inherit lib diagnostics; };

    # Settings modules by catalogue name; every bundle has one.
    configure = {
      base = ./_configure/base.nix;
      window-management = ./_configure/window-management.nix;
      unified-ui = ./_configure/unified-ui.nix;
      file-handling = ./_configure/file-handling.nix;
      power = ./_configure/power.nix;
      laptop = ./_configure/laptop.nix;
      vm = ./_configure/vm.nix;
      core-apps = ./_configure/core-apps.nix;
      gaming = ./_configure/gaming.nix;
      flashgbx = ./_configure/flashgbx.nix;
      gpg = ./_configure/gpg.nix;
      tailscale = ./_configure/tailscale.nix;
    };

  });

  # Present on every host; the host's bundles list decides what it does.
  flake.modules.nixos.features.imports = [
    config.flake.nixosModules.bundles-options
    config.flake.nixosModules.bundles
  ];
}
