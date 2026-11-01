{ lib }:
let
  inherit (lib) mkOption types;
in
rec {

  file = types.submodule {
    options = {

      owner = mkOption {
        type = types.str;
        default = "root";
      };

      group = mkOption {
        type = types.str;
        default = "root";
      };

      mode = mkOption {
        type = types.str;
        default = "0400";
      };

    };
  };

  # A declared secret, resolved against the repository.
  modelFile = types.submodule {
    options = {
      owner = mkOption { type = types.str; };
      group = mkOption { type = types.str; };
      mode = mkOption { type = types.str; };

      source = mkOption {
        type = types.path;
        description = "secrets/<name>.age in the repository.";
      };

      exists = mkOption { type = types.bool; };

      hasRule = mkOption {
        type = types.bool;
        description = "Whether secrets.nix has an entry for it.";
      };

      forHost = mkOption {
        type = types.bool;
        description = "Whether the host's key is among its recipients.";
      };
    };
  };

  model = types.submodule {
    options = {

      files = mkOption {
        type = types.attrsOf modelFile;
      };

      host = mkOption {
        type = types.submodule {
          options = {
            name = mkOption { type = types.str; };
            key = mkOption { type = types.nullOr types.str; };
          };
        };
      };

      identity = mkOption {
        type = types.submodule {
          options = {
            paths = mkOption { type = types.listOf types.str; };

            sshHostKey = mkOption {
              type = types.bool;
              description = "Whether an identity is an SSH host key.";
            };

            provided = mkOption {
              type = types.bool;
              description = "Whether something creates that key (sshd, or provisioned by hand).";
            };
          };
        };
      };

    };
  };

}
