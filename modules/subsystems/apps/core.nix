#
# The apps core, laid out like the storage core:
#
#   _domain/     app fields, roles and model types; the catalogue; the
#                default role selection
#   _usecases/   normalize (roles -> resolved apps), validate
#   _configure/  how an app is configured, per catalogue name (module
#                functions, enabled when the app plays a role or is
#                installed)
#
# api.nix and module.nix beside this file are the outer ring. The
# desktop (binds, dock, launcher, clipboard) and the shell (editor
# alias) read the resolved roles from ltp.apps.facts.
#
{ config, lib, ... }:
let
  inherit (config.flake.subsystems) diagnostics overrides;
in
{
  flake.subsystems.apps = lib.fix (apps: {

    types = import ./_domain/types.nix { inherit lib overrides; };

    catalog = import ./_domain/catalog.nix { };

    defaultRoles = import ./_domain/roles.nix { };

    normalize = import ./_usecases/normalize.nix { inherit lib apps; };

    validate = import ./_usecases/validate.nix { inherit lib apps diagnostics; };

    # Configure modules by catalogue name; apps without one need no setup.
    configure = {
      alacritty = ./_configure/alacritty.nix;
      nixvim = ./_configure/nixvim;
    };

  });
}
