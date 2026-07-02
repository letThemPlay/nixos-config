{ lib, ... }: {
  options.ltp.users.registry = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          username = lib.mkOption { type = lib.types.str; };
          fullName = lib.mkOption { type = lib.types.str; };
          email = lib.mkOption { type = lib.types.str; };
          admin = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          features = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
          extraPackages = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
          theme = lib.mkOption {
            type = lib.types.str;
            default = "tokyonight";
          };

          defaultShell = lib.mkOption {
            type = lib.types.enum [
              "bash"
              "zsh"
            ];
            default = "bash";
            description = "The primary interactive terminal shell for this user profile";
          };
        };
      }
    );
    default = { };
    description = "The central, unified registry for all user personas across the flake.";
  };
}
