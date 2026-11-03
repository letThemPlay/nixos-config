{ lib }:
let
  inherit (lib) mkOption types;

  cache = types.submodule {
    options = {

      url = mkOption {
        type = types.str;
        example = "https://nix-community.cachix.org";
        description = "Substituter URL (https).";
      };

      key = mkOption {
        type = types.str;
        example = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
        description = "Trusted public key, <name>:<base64>.";
      };

    };
  };

  gc = types.submodule {
    options = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether old store paths are collected periodically.";
      };

      dates = mkOption {
        type = types.str;
        default = "weekly";
        description = "systemd calendar expression for the collection.";
      };

      olderThan = mkOption {
        type = types.str;
        default = "30d";
        description = "Delete generations older than this (<n>d, <n>h or <n>w).";
      };

    };
  };

  ld = types.submodule {
    options = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether nix-ld runs unpatched dynamically linked binaries.";
      };

      defaultLibraries = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the default libraries (CLI and desktop) are offered.";
      };

      libraries = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "openal" ];
        description = ''
          Further libraries, as pkgs attribute paths. NixOS's own base
          set (zlib, openssl, curl, libstdc++, systemd, …) is always
          offered.
        '';
      };

    };
  };

  model = types.submodule {
    options = {

      package = mkOption {
        type = types.submodule {
          options = {
            path = mkOption { type = types.str; };
            known = mkOption { type = types.bool; };
          };
        };
      };

      experimentalFeatures = mkOption {
        type = types.listOf types.str;
      };

      optimiseStore = mkOption {
        type = types.bool;
      };

      caches = mkOption {
        type = types.attrsOf cache;
        description = "Default caches merged with added ones.";
      };

      gc = mkOption {
        type = gc;
      };

      ld = mkOption {
        type = types.submodule {
          options = {
            enable = mkOption { type = types.bool; };

            libraries = mkOption {
              type = types.listOf (
                types.submodule {
                  options = {
                    path = mkOption { type = types.str; };
                    known = mkOption { type = types.bool; };
                  };
                }
              );
              description = "Defaults and added libraries, each once.";
            };
          };
        };
      };

    };
  };
in
{
  inherit
    cache
    gc
    ld
    model
    ;
}
