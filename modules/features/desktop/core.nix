#
# The desktop core, laid out like the storage core:
#
#   _domain/    entities: bind, service, bar and model types; the action
#               vocabulary; default window-management binds
#   _usecases/  normalize (host and component settings -> model),
#               validate
#   _adapters/  compositors/<name> (registry), waybar-config (a bar's
#               waybar config for one compositor), systemd user
#               units, quickshell (the shell's generated QML)
#
# options.nix and module.nix beside this file are the outer ring.
# Components (bar, launcher, notifier, ...) are a registry in
# _components/<role>/<name>.nix, selected per role with
# ltp.desktop.components; they contribute binds, bar widgets and
# services to ltp.desktop like any feature. _ui/ is the QML of the
# unified shell that the quickshell components share.
#
{ config, lib, ... }:
let
  inherit (config.ltp.features) diagnostics;
in
{
  ltp.features.desktop = lib.fix (desktop: {

    types = import ./_domain/types.nix { inherit lib desktop; };

    actions = import ./_domain/actions.nix { };

    defaultBinds = import ./_domain/default-binds.nix { };

    defaultWindowRules = import ./_domain/default-window-rules.nix { };

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
    #   system     : { package; portals; keyring; packages; } as names
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
      bar = {
        waybar = ./_components/bar/waybar.nix;
        quickshell = ./_components/bar/quickshell.nix;
      };
      dock.waybar = ./_components/dock/waybar.nix;
      launcher = {
        fuzzel = ./_components/launcher/fuzzel.nix;
        quickshell = ./_components/launcher/quickshell.nix;
      };
      notifier = {
        mako = ./_components/notifier/mako.nix;
        quickshell = ./_components/notifier/quickshell.nix;
      };
      locker = {
        hyprlock = ./_components/locker/hyprlock.nix;
        quickshell = ./_components/locker/quickshell.nix;
      };
      power.quickshell = ./_components/power/quickshell.nix;
      polkit.quickshell = ./_components/polkit/quickshell.nix;
      osd.quickshell = ./_components/osd/quickshell.nix;
      quicksettings.quickshell = ./_components/quicksettings/quickshell.nix;
      batteryAlerts.quickshell = ./_components/batteryAlerts/quickshell.nix;
      displays.kanshi = ./_components/displays/kanshi.nix;
      automount.udiskie = ./_components/automount/udiskie.nix;
      clipboard = {
        cliphist = ./_components/clipboard/cliphist.nix;
        quickshell = ./_components/clipboard/quickshell.nix;
      };
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
      power = null;
      polkit = null;
      osd = null;
      quicksettings = null;
      batteryAlerts = null;
      displays = null;
      automount = null;
      clipboard = "cliphist";
      screenshot = "grim";
      wallpaper = "swaybg";
      media = "playerctl";
    };

    #
    # The unified shell (_ui): one Quickshell config drawing every role that
    # selects this component name, on one theme and one set of controls.
    #
    uiComponent = "quickshell";

    uiSource = ./_ui;

    uiInstance = import ./_ui/instance.nix;

    # The bar widgets the shell draws (_ui/bar/Bar.qml).
    uiWidgets = [
      "launcher"
      "notifications"
      "workspaces"
      "window"
      "tray"
      "media"
      "network"
      "bluetooth"
      "volume"
      "battery"
      "clock"
      "settings"
      "power"
    ];

    powerActions = import ./_domain/power-actions.nix { };

    quickshell = import ./_adapters/quickshell.nix { inherit lib; };

    kanshi = import ./_adapters/kanshi.nix { inherit lib; };

    # Spawned commands run as session applications.
    spawnPrefix = [
      "uwsm"
      "app"
      "--"
    ];

    waybarConfig = import ./_adapters/waybar-config.nix { inherit lib; };

    systemdUnits = import ./_adapters/systemd-units.nix { inherit lib desktop; };

  });

  # Present on every host; bundles and host settings decide what it does.
  flake.modules.nixos.features.imports = [
    config.flake.nixosModules.desktop-options
    config.flake.nixosModules.desktop
  ];
}
