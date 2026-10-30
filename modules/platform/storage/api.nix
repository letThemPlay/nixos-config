{ config, ... }:
let
  storage = config.flake.library.storage;
in
{
  flake.nixosModules.storage-api =
    { lib, ... }:
    let
      inherit (lib)
        mkEnableOption
        mkOption
        types
        ;
    in
    {
      options.ohmydarlings.storage = {

        enable = mkEnableOption "Oh My Darlings storage subsystem";

        backend = mkOption {
          type = types.enum [ "disko" ];
          default = "disko";

          description = "Storage renderer.";
        };

        layout = mkOption {
          type = types.str;
          default = "erase-my-darlings";

          description = ''
            Logical storage layout.
          '';
        };

        disk = mkOption {
          type = types.str;

          example = "/dev/disk/by-id/nvme-Samsung_990_PRO";
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
            type = types.enum [ "btrfs" ];
            default = "btrfs";
          };

          compression = mkOption {
            type = types.str;
            default = "zstd";
          };

        };

        volumes = mkOption {
          type = types.attrsOf storage.types.volume;

          default = { };

          description = ''
            Canonical filesystem model.

            Storage backends consume this model to produce
            backend-specific configuration.
          '';
        };
        persistence = {

          policy = mkOption {
            type = types.attrsOf (
              types.submodule {
                options = {

                  directories = mkOption {
                    type = types.listOf types.str;
                    default = [ ];

                    description = ''
                      Directories to preserve on this storage volume.
                    '';
                  };

                  files = mkOption {
                    type = types.listOf types.str;
                    default = [ ];

                    description = ''
                      Files to preserve on this storage volume.
                    '';
                  };

                };
              }
            );

            default = { };

            description = ''
              Persistence policy grouped by storage volume identifier.

              Each attribute name must refer to a volume defined in
              storage.volumes.
            '';
          };

        };
      };
    };
}
