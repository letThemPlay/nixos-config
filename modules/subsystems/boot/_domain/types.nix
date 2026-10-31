{ lib, boot }:
let
  inherit (lib) mkOption types;
in
{

  # Valid loaders are the keys of the loader registry.
  loader = types.enum (builtins.attrNames boot.loaders);

  model = types.submodule {
    options = {

      loader = mkOption {
        type = types.submodule {
          options = {

            name = mkOption {
              type = types.str;

              description = ''
                Selected loader: the host's choice, or the automatic one.
              '';
            };

            known = mkOption {
              type = types.bool;

              description = ''
                Whether the loader exists in the loader registry.
              '';
            };

            secureBoot = mkOption {
              type = types.bool;

              description = ''
                Whether the loader signs boot files for Secure Boot.
              '';
            };

          };
        };
      };

      generations = mkOption {
        type = types.ints.positive;

        description = ''
          Generations kept in the boot menu.
        '';
      };

      secureBoot = mkOption {
        type = types.submodule {
          options = {

            enable = mkOption {
              type = types.bool;
            };

            pkiBundle = mkOption {
              type = types.str;
            };

          };
        };
      };

      tpmUnlock = mkOption {
        type = types.submodule {
          options = {

            enable = mkOption {
              type = types.bool;
            };

            luksName = mkOption {
              type = types.nullOr types.str;

              description = ''
                LUKS mapping of the root filesystem, from the storage
                facts; null when the root is not encrypted.
              '';
            };

          };
        };
      };

    };
  };

}
