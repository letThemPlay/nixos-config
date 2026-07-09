_: {
  flake.nixosModules.storage-api =
    {
      lib,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkOption
        types
        ;

      volumeType = types.submodule (
        { name, ... }:
        {
          options = {
            name = mkOption {
              type = types.str;
              default = "@${name}";
              description = "Backend-specific volume name.";
            };

            mountpoint = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "/";
            };

            mountOptions = mkOption {
              type = types.listOf types.str;
              default = [ ];
            };

            neededForBoot = mkOption {
              type = types.bool;
              default = false;
            };

            persistent = mkOption {
              type = types.bool;
              default = false;
            };

            rollback = mkOption {
              type = types.bool;
              default = false;
            };

            snapshot = mkOption {
              type = types.bool;
              default = false;
            };
          };
        }
      );
    in
    {
      options.ohmydarlings.storage = {

        enable = mkEnableOption "Oh My Darlings storage subsystem";

        backend = mkOption {
          type = types.enum [
            "disko"
          ];

          default = "disko";
        };

        disk = mkOption {
          type = types.str;
          example = "/dev/disk/by-id/nvme-Samsung_990";
        };

        boot = {

          efiSize = mkOption {
            type = types.str;
            default = "1G";
          };

        };

        swap = {

          enable = mkEnableOption "swap";

          size = mkOption {
            type = types.str;
            default = "16G";
          };

        };

        encryption = {

          enable = mkEnableOption "LUKS";

          label = mkOption {
            type = types.str;
            default = "cryptroot";
          };

          allowDiscards = mkOption {
            type = types.bool;
            default = true;
          };

        };

        filesystem = {

          type = mkOption {
            type = types.enum [
              "btrfs"
            ];

            default = "btrfs";
          };

          compression = mkOption {
            type = types.str;
            default = "zstd";
          };

        };

        volumes = mkOption {
          type = types.attrsOf volumeType;
          default = { };
        };

        persistence = {

          directories = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };

          files = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };

        };
      };
    };
}
