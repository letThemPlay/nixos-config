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

    bundles = {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Bundles this user wants, by bundle name. Each one applies on
        hosts that include that bundle and is skipped on the others.
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
      description = "Theme name; the theme feature checks it against its catalogue.";
    };

    shell = {
      type = types.str;
      default = "bash";
      description = "Login shell; the shell feature checks and renders it.";
    };

    gpg = {
      type = gpg;
      default = { };
      description = ''
        The user's OpenPGP setup. Rendered only on hosts with
        ltp.identity.gpg.enable.
      '';
    };

  };

  # A user's OpenPGP keys; the loader fills keys from gpg/<user>/*.asc.
  gpg = types.submodule {
    options = {

      keys = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = "Public keys (armoured .asc files), imported with ultimate trust.";
      };

      signingKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "0x5D0149C121F819A6";
        description = "Key that signs git commits: a 16-hex key ID (optionally 0x) or a 40-hex fingerprint.";
      };

      smartcard = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the secret keys live on a smartcard (installs its device rules).";
      };

      ssh = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether gpg-agent serves SSH; null: when there is a signing key or a smartcard.";
      };

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

      escalation = mkOption {
        type = types.submodule {
          options = {
            name = mkOption {
              type = types.nullOr types.str;
              description = "Tool admin users get root with; null for none.";
            };

            known = mkOption {
              type = types.bool;
              description = "Whether the tool is registered (true for null).";
            };
          };
        };
      };

      gpg = mkOption {
        type = types.bool;
        description = "Whether this host renders the users' OpenPGP setup.";
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

            bundles = mkOption {
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
