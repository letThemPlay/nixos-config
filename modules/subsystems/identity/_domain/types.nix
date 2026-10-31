{ lib }:
let
  inherit (lib) mapAttrs mkOption types;
in
rec {

  #
  # User fields, declared once. `user` is the catalogue entry a user
  # file defines; `modelUser` is the normalized form with derived
  # values. Neither has a freeform type, so an unknown field in a user
  # file is an error.
  #
  userFields = {

    fullName = {
      type = types.str;
      description = "Display name of the user.";
    };

    email = {
      type = types.str;
      description = "Email address, used for git.";
    };

    admin = {
      type = types.bool;
      default = false;
      description = "Whether the user is in wheel.";
    };

    features = {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Features this user wants, by feature registry name. Each one
        applies on hosts that include that feature and is skipped on
        the others.
      '';
    };

    extraPackages = {
      type = types.listOf types.str;
      default = [ ];
      description = "Package attribute names installed for this user.";
    };

    extraGroups = {
      type = types.listOf types.str;
      default = [ ];
      description = "Groups added to the defaults (video, audio, wheel for admins).";
    };

    theme = {
      type = types.str;
      default = "tokyonight";
      description = "Theme name from the theme catalog.";
    };

    shell = {
      type = types.enum [
        "bash"
        "zsh"
      ];
      default = "bash";
      description = "Login shell.";
    };

  };

  fieldOptions = mapAttrs (
    _: spec:
    mkOption (
      {
        inherit (spec) type description;
      }
      // lib.optionalAttrs (spec ? default) { inherit (spec) default; }
    )
  ) userFields;

  user = types.submodule (
    { name, ... }:
    {
      options = fieldOptions // {

        username = mkOption {
          type = types.str;
          default = name;
          readOnly = true;
          description = "Login name; the attribute name.";
        };

        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether this user exists on the host. Set by the host factory.";
        };

      };
    }
  );

  modelUser = types.submodule {
    options = fieldOptions // {

      username = mkOption {
        type = types.str;
      };

      groups = mkOption {
        type = types.listOf types.str;
        description = "Default groups, extraGroups and wheel for admins.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.str;
        description = "Hashed password file, or null when passwords are not managed.";
      };

    };
  };

  model = types.submodule {
    options = {

      users = mkOption {
        type = types.attrsOf modelUser;
        description = "Users enabled on the host.";
      };

      ephemeral = mkOption {
        type = types.bool;
        description = "Whether / and /etc are recreated on every boot.";
      };

      statePath = mkOption {
        type = types.nullOr types.str;
      };

      passwordDirectory = mkOption {
        type = types.nullOr types.str;
      };

      #
      # What the user entries may refer to. Null means the host does
      # not provide that catalogue, and the check is skipped.
      #
      known = mkOption {
        type = types.submodule {
          options = {

            themes = mkOption {
              type = types.nullOr (types.listOf types.str);
            };

            features = mkOption {
              type = types.nullOr (types.listOf types.str);
            };

            packages = mkOption {
              type = types.listOf types.str;
              description = "The users' extraPackages names that exist in pkgs.";
            };

          };
        };
      };

    };
  };

}
