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
# options.nix and module.nix beside this file are the outer ring.
# Components (bar, launcher, notifier, ...) are a registry in
# _components/<role>/<name>.nix, selected per role with
# ltp.desktop.components; they contribute binds, bar widgets and
# services to ltp.desktop like any feature.
#
{ config, lib, ... }:
let
  inherit (config.flake.features) diagnostics;
in
{
  flake.features.desktop = lib.fix (desktop: {

    types = import ./_domain/types.nix { inherit lib desktop; };

    actions = import ./_domain/actions.nix { };

    defaultBinds = import ./_domain/binds.nix { };

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

    #
    # Component registry: role -> name -> NixOS module function
    # ({ config, lib, pkgs, ... } -> settings). The desktop module
    # imports every one and enables the one ltp.desktop.components
    # selects for each role. Components contribute to ltp.desktop
    # (binds, bar, services, rules) like any feature.
    #
    components = {
      bar.waybar = ./_components/bar/waybar.nix;
      dock.waybar = ./_components/dock/waybar.nix;
      launcher.fuzzel = ./_components/launcher/fuzzel.nix;
      notifier.mako = ./_components/notifier/mako.nix;
      locker.hyprlock = ./_components/locker/hyprlock.nix;
      clipboard.cliphist = ./_components/clipboard/cliphist.nix;
      screenshot.grim = ./_components/screenshot/grim.nix;
      wallpaper.swaybg = ./_components/wallpaper/swaybg.nix;
      media.playerctl = ./_components/media/playerctl.nix;
    };

    # The selection when a host sets nothing.
    defaultComponents = {
      bar = "waybar";
      dock = "waybar";
      launcher = "fuzzel";
      notifier = "mako";
      locker = "hyprlock";
      clipboard = "cliphist";
      screenshot = "grim";
      wallpaper = "swaybg";
      media = "playerctl";
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
