#
# The desktop core, laid out like the storage core:
#
#   _domain/    entities: bind, service, bar and model types; the action
#               vocabulary; default window-management binds
#   _usecases/  normalize (host and component settings -> model),
#               validate
#   _adapters/  compositors/<name> (registry), waybar bar config,
#               systemd user units
#
# api.nix and module.nix beside this file are the outer ring.
# Components (bar, launcher, notifier, ...) are features that
# contribute binds, bar widgets and services to ltp.desktop.
#
{ config, lib, ... }:
let
  inherit (config.flake.subsystems) diagnostics overrides;
in
{
  flake.subsystems.desktop = lib.fix (desktop: {

    types = import ./_domain/types.nix { inherit lib desktop overrides; };

    actions = import ./_domain/actions.nix { };

    defaultBinds = import ./_domain/binds.nix { };

    defaultApps = import ./_domain/apps.nix { };

    defaultWindowRules = import ./_domain/rules.nix { };

    normalize = import ./_usecases/normalize.nix { inherit lib desktop; };

    validate = import ./_usecases/validate.nix { inherit lib desktop diagnostics; };

    #
    # Compositor registry. The keys are the valid values of
    # ltp.desktop.compositors. An entry provides:
    #
    #   session    : desktop name (XDG_CURRENT_DESKTOP)
    #   configFile : path under ~/.config
    #   actions    : vocabulary name -> native bind action
    #   widgets    : abstract bar widget -> waybar module
    #   ruleProperties : window rule properties it can render
    #   uwsm       : { prettyName; comment; binPath; extraArgs; } for its
    #                uwsm session
    #   system     : { package; portals; keyring; } as names
    #   render     : { model, spawnPrefix } -> config text
    #
    compositors = {
      niri = import ./_adapters/compositors/niri.nix { inherit lib; };
    };

    #
    # Greeter registry, keyed like ltp.desktop.greeter:
    #   { pkgs, sessionsDir } -> { command; }
    #   (NixOS creates the tuigreet cache directory for greetd.)
    #
    greeters = {
      tuigreet = import ./_adapters/greeters/tuigreet.nix { };
    };

    # Spawned commands run as session applications.
    spawnPrefix = [
      "uwsm"
      "app"
      "--"
    ];

    waybar = import ./_adapters/waybar.nix { inherit lib; };

    systemdUnits = import ./_adapters/systemd-units.nix { inherit lib desktop; };

  });
}
