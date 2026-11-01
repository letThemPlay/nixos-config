{
  lib,
  desktop,
}:
let
  inherit (lib) mkOption types;
in
rec {

  # Valid compositors are the keys of the compositor registry.
  compositor = types.enum (builtins.attrNames desktop.compositors);

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

    requires = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Hardware facts (ltp.hardware.facts) the bind needs, e.g. \"audio\".";
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

      requires = mkOption {
        type = types.attrsOf (types.listOf types.str);
        default = { };
        example = {
          bluetooth = [ "bluetooth" ];
        };
        description = "Hardware facts each widget needs; widgets without them are left out.";
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

      appRoles = mkOption {
        type = types.listOf types.str;
        description = "Roles the apps subsystem resolved; app binds must name one.";
      };

      windowRules = mkOption {
        type = types.attrsOf windowRule;
      };

      idle = mkOption {
        type = idle;
      };

      requirements = mkOption {
        type = types.submodule {
          options = {
            known = mkOption {
              type = types.nullOr (types.listOf types.str);
              description = "Hardware fact names; null when none were given.";
            };
            used = mkOption { type = types.listOf types.str; };
            droppedBinds = mkOption { type = types.attrsOf (types.listOf types.str); };
          };
        };
      };

      components = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              name = mkOption { type = types.nullOr types.str; };
              known = mkOption { type = types.bool; };
            };
          }
        );
        description = "Selected component per role.";
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
