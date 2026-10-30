{ lib, ... }:
{
  flake.library.storageTypes =
    let
      inherit (lib) mkOption types;
    in
    rec {
      severity = types.enum [
        "error"
        "warning"
        "info"
      ];

      backend = types.enum [
        "btrfs"
      ];

      volume = types.submodule (
        { name, ... }:
        {
          options = {

            id = mkOption {
              type = types.str;
              default = name;
              readOnly = true;

              description = ''
                Canonical identifier for this volume.

                Assigned during normalization from the attribute name.
                Consumers should treat this as immutable.
              '';
            };

            role = mkOption {
              type = types.str;
              default = name;

              description = ''
                Semantic role of this filesystem object.

                Renderers should identify important volumes by role
                rather than by attribute name.
              '';
            };

            category = mkOption {
              type = types.enum [
                "system"
                "state"
                "store"
                "user"
                "snapshot"
                "template"
                "runtime"
              ];

              default = "state";

              description = ''
                Classification of the data stored by this volume.
              '';
            };

            backend = mkOption {
              type = types.nullOr types.str;
              default = null;

              description = ''
                Optional backend override.

                When null, the backend is inherited from the storage
                model during normalization.
              '';
            };

            name = mkOption {
              type = types.str;
              default = "@${name}";

              description = ''
                Backend-specific identifier.

                Examples include:

                • Btrfs subvolumes
                • ZFS datasets
                • LVM logical volumes
              '';
            };

            mountpoint = mkOption {
              type = types.nullOr types.str;
              default = null;

              description = ''
                Filesystem mountpoint.

                Null indicates this volume is not mounted directly.
              '';
            };

            mountOptions = mkOption {
              type = types.listOf types.str;
              default = [ ];

              description = ''
                Additional mount options appended to the backend defaults.
              '';
            };

            neededForBoot = mkOption {
              type = types.bool;
              default = false;

              description = ''
                Indicates this volume must be mounted during early boot.
              '';
            };

            snapshot = mkOption {
              type = types.bool;
              default = false;

              description = ''
                Indicates this volume participates in snapshot creation.
              '';
            };

            rollback = mkOption {
              type = types.bool;
              default = false;

              description = ''
                Indicates this volume participates in rollback.
              '';
            };

          };
        }
      );

      persistence = types.submodule {
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
      };

      layout = types.submodule {
        options = {

          version = mkOption {
            type = types.int;
            default = 1;

            description = ''
              Layout schema version.
            '';
          };

          description = mkOption {
            type = types.lines;

            description = ''
              Human-readable description of this layout.
            '';
          };

          requiredRoles = mkOption {
            type = types.listOf types.str;
            default = [ ];

            description = ''
              Semantic roles that must exist within this layout.
            '';
          };

          volumes = mkOption {
            type = types.attrsOf volume;
            default = { };

            description = ''
              Canonical volume definitions supplied by the layout.
            '';
          };

        };
      };

      model = types.submodule {
        options = {

          version = mkOption {
            type = types.int;

            description = ''
              Storage model schema version.
            '';
          };

          layout = mkOption {
            type = types.submodule {
              options = {

                name = mkOption {
                  type = types.str;

                  description = ''
                    Name of the selected storage layout.
                  '';
                };

                known = mkOption {
                  type = types.bool;

                  description = ''
                    Whether the selected layout exists in the layout library.
                  '';
                };

                version = mkOption {
                  type = types.int;

                  description = ''
                    Version of the selected layout.
                  '';
                };

                description = mkOption {
                  type = types.lines;

                  description = ''
                    Human-readable description of the selected layout.
                  '';
                };

                requiredRoles = mkOption {
                  type = types.listOf types.str;

                  description = ''
                    Roles required by this layout.
                  '';
                };

              };
            };

            description = ''
              Metadata describing the selected storage layout.
            '';
          };

          renderer = mkOption {
            type = types.str;

            description = ''
              Tool that renders this model into host configuration.
            '';
          };

          backend = mkOption {
            type = types.str;

            description = ''
              Normalized storage backend.

              Every volume inherits this backend unless overridden.
            '';
          };

          volumes = mkOption {
            type = types.attrsOf volume;

            description = ''
              Fully normalized storage model.

              All inheritance has been resolved before the model reaches
              query, validation or rendering.
            '';
          };

          persistence = mkOption {
            type = types.attrsOf persistence;
            default = { };

            description = ''
              Persistence policy grouped by storage volume identifier.

              Each attribute name must refer to a volume defined in
              the storage model.
            '';
          };

          rollback = mkOption {
            type = types.submodule {
              options.keepSnapshots = mkOption {
                type = types.ints.unsigned;

                description = ''
                  Pre-rollback snapshots kept per volume.
                '';
              };
            };

            description = ''
              Rollback behaviour for volumes marked rollback.
            '';
          };

          platform = mkOption {
            type = types.attrsOf types.anything;

            description = ''
              Device-level settings consumed by renderers:
              disk, boot, swap, encryption and filesystem.
            '';
          };

        };
      };

    };

}
