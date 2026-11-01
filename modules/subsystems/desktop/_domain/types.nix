{
  lib,
  desktop,
  overrides,
}:
let
  inherit (lib) mkOption types;
in
rec {

  # Valid compositors are the keys of the compositor registry.
  compositor = types.enum (builtins.attrNames desktop.compositors);

  #
  # App role fields, declared once. `app` is the full entity; `appOverride`
  # is the host-facing partial form: only the fields it defines apply.
  # normalize merges appDefaults <- default role <- override, like
  # storage volumes.
  #
  appFields = {

    package = {
      type = types.str;
      description = "Package attribute path in pkgs.";
    };

    command = {
      type = types.listOf types.str;
      description = "Command and arguments that start the app.";
    };

    appId = {
      type = types.str;
      description = "Wayland app id of its windows.";
    };

    inTerminal = {
      type = types.bool;
      description = "Whether the app runs inside the terminal role.";
    };

    execFlag = {
      type = types.nullOr types.str;
      description = "For a terminal: the flag that runs a command in it (e.g. -e).";
    };

  };

  appDefaults = role: {
    package = role;
    command = [ role ];
    appId = role;
    inTerminal = false;
    execFlag = null;
  };

  appOverride = overrides.type appFields;

  applyAppOverride = overrides.apply appFields;

  # A resolved role: command already wrapped in the terminal when needed.
  app = types.submodule {
    options = lib.mapAttrs (_: spec: mkOption { inherit (spec) type description; }) appFields // {
      known = mkOption {
        type = types.bool;
        description = "Whether the package exists in pkgs.";
      };
    };
  };

  #
  # A key bind runs a command, a vocabulary action or an app role,
  # exactly one of them. Spawned commands are started as session
  # applications (uwsm app --).
  #
  bindFields = {

    spawn = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "Command and arguments to start.";
    };

    action = mkOption {
      type = types.nullOr (types.enum desktop.actions);
      default = null;
      description = "Window action from the vocabulary.";
    };

    app = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "App role to start, e.g. \"terminal\".";
    };

  };

  bind = types.submodule { options = bindFields; };

  # A bind in the model: command is the final argv (spawn or the role's).
  modelBind = types.submodule {
    options = bindFields // {
      command = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
      };
    };
  };

  #
  # A compositor-neutral window rule: what it matches and the properties
  # it sets. Null means "not set"; a compositor reports properties it
  # cannot render.
  #
  windowRule = types.submodule {
    options = {

      match = {
        appId = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Regular expression on the window's app id.";
        };

        isActive = mkOption {
          type = types.nullOr types.bool;
          default = null;
        };
      };

      opacity = mkOption {
        type = types.nullOr types.float;
        default = null;
      };

      shadow = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              softness = mkOption { type = types.ints.unsigned; };
              color = mkOption { type = types.str; };
              offset = {
                x = mkOption { type = types.int; };
                y = mkOption { type = types.int; };
              };
            };
          }
        );
        default = null;
      };

      focusRing = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };

      floating = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Open the window floating.";
      };

    };
  };

  #
  # When the idle session locks and suspends, in seconds. Null skips
  # that step.
  #
  idle = types.submodule {
    options = {

      lockAfter = mkOption {
        type = types.nullOr types.ints.positive;
        default = 300;
      };

      suspendAfter = mkOption {
        type = types.nullOr types.ints.positive;
        default = 900;
      };

    };
  };

  # The properties a rule can set, for compositor capability checks.
  ruleProperties = [
    "opacity"
    "shadow"
    "focusRing"
    "floating"
  ];

  #
  # A background component, run as a systemd user service in the
  # graphical session. exec may be a function of the user's
  # home-manager { config, osConfig } for per-user arguments.
  #
  service = types.submodule {
    options = {

      description = mkOption {
        type = types.str;
      };

      exec = mkOption {
        type = types.either (types.listOf types.str) (types.functionTo (types.listOf types.str));
        description = "Command and arguments; %h expands to the home directory.";
      };

      restart = mkOption {
        type = types.str;
        default = "on-failure";
      };

      compositors = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Sessions the service runs in; null means every session.";
      };

    };
  };

  #
  # The status bar. Module names are waybar's, except abstract widgets
  # such as "workspaces", which each compositor resolves.
  #
  bar = types.submodule {
    options = {

      left = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };

      center = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };

      right = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };

      settings = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Bar and module settings, keyed like waybar's config.";
      };

    };
  };

  model = types.submodule {
    options = {

      compositors = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              name = mkOption { type = types.str; };
              known = mkOption { type = types.bool; };
            };
          }
        );
      };

      binds = mkOption {
        type = types.attrsOf modelBind;
        description = "Defaults merged with component and host binds.";
      };

      apps = mkOption {
        type = types.attrsOf app;
        description = "App roles, resolved.";
      };

      windowRules = mkOption {
        type = types.attrsOf windowRule;
      };

      idle = mkOption {
        type = idle;
      };

      greeter = mkOption {
        type = types.submodule {
          options = {
            name = mkOption { type = types.nullOr types.str; };
            known = mkOption { type = types.bool; };
          };
        };
      };

      bar = mkOption {
        type = bar;
      };

      services = mkOption {
        type = types.attrsOf service;
      };

      # The session keyboard, from ltp.locale.
      keyboard = {
        layout = mkOption { type = types.str; };
        variant = mkOption { type = types.str; };
      };

    };
  };

}
