{ lib, desktop }:
let
  inherit (lib) mkOption types;
in
rec {

  # Valid compositors are the keys of the compositor registry.
  compositor = types.enum (builtins.attrNames desktop.compositors);

  #
  # A key bind runs a command or a vocabulary action, not both. Spawned
  # commands are started as session applications (uwsm app --).
  #
  bind = types.submodule {
    options = {

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

    };
  };

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
        type = types.attrsOf bind;
        description = "Defaults merged with component and host binds.";
      };

      bar = mkOption {
        type = bar;
      };

      services = mkOption {
        type = types.attrsOf service;
      };

      keyboard.layout = mkOption {
        type = types.str;
      };

    };
  };

}
