{ lib, storage }:
let
  inherit (lib) mapAttrs mkOption types;
in
rec {
  severity = types.enum [
    "error"
    "warning"
    "info"
  ];

  # Valid backends are the keys of the backend registry.
  backend = types.enum (builtins.attrNames storage.backends);

  #
  # Volume fields, declared once. `volume` is the full entity used by
  # layouts and the model; `volumeOverride` is the host-facing
  # partial form where null means "not set". normalize merges
  # volumeDefaults <- layout volume <- override.
  #
  volumeFields = {

    role = {
      type = types.str;

      description = ''
        Semantic role of this filesystem object.

        Renderers should identify important volumes by role
        rather than by attribute name.
      '';
    };

    category = {
      type = types.enum [
        "system"
        "state"
        "store"
        "user"
        "snapshot"
        "template"
        "runtime"
      ];

      description = ''
        Classification of the data stored by this volume.
      '';
    };

    backend = {
      type = types.nullOr types.str;

      description = ''
        Optional backend override.

        When null, the backend is inherited from the storage
        model during normalization.
      '';
    };

    name = {
      type = types.str;

      description = ''
        Backend-specific identifier.

        Examples include:

        • Btrfs subvolumes
        • ZFS datasets
        • LVM logical volumes
      '';
    };

    mountpoint = {
      type = types.nullOr types.str;

      description = ''
        Filesystem mountpoint.

        Null indicates this volume is not mounted directly.
      '';
    };

    mountOptions = {
      type = types.listOf types.str;

      description = ''
        Additional mount options appended to the backend defaults.
      '';
    };

    neededForBoot = {
      type = types.bool;

      description = ''
        Indicates this volume must be mounted during early boot.
      '';
    };

    snapshot = {
      type = types.bool;

      description = ''
        Indicates this volume participates in snapshot creation.
      '';
    };

    rollback = {
      type = types.bool;

      description = ''
        Indicates this volume participates in rollback.
      '';
    };

  };

  # Defaults for a volume with the given identifier.
  volumeDefaults = id: {
    role = id;
    category = "state";
    backend = null;
    name = "@${id}";
    mountpoint = null;
    mountOptions = [ ];
    neededForBoot = false;
    snapshot = false;
    rollback = false;
  };

  volume = types.submodule (
    { name, ... }:
    {
      options = {

        id = mkOption {
          type = types.str;
          default = name;

          description = ''
            Canonical identifier for this volume.

            Assigned during normalization from the attribute name.
            Consumers should treat this as immutable.
          '';
        };

      }
      // mapAttrs (
        field: spec:
        mkOption {
          inherit (spec) type description;
          default = (volumeDefaults name).${field};
        }
      ) volumeFields;
    }
  );

  #
  # Host override of a layout volume, or a new volume. Only fields
  # that are set (non-null) replace the layout value; a layout
  # volume therefore cannot be un-mounted by an override.
  #
  volumeOverride = types.submodule {
    options = mapAttrs (
      _: spec:
      mkOption {
        type = types.nullOr spec.type;
        default = null;
        inherit (spec) description;
      }
    ) volumeFields;
  };

  #
  # A preserved path: either a plain absolute path or an attrset with
  # renderer-specific settings. Typed settings default to null so
  # renderers only receive what was set explicitly; unknown keys are
  # passed through untouched.
  #
  persistenceEntry =
    kind:
    types.either types.str (
      types.submodule {
        freeformType = types.attrsOf types.anything;

        options = {

          ${kind} = mkOption {
            type = types.str;

            description = ''
              Absolute path to preserve.
            '';
          };

          how = mkOption {
            type = types.nullOr (
              types.enum [
                "bindmount"
                "symlink"
              ]
            );
            default = null;

            description = ''
              Whether the path is bind-mounted or symlinked.
            '';
          };

          inInitrd = mkOption {
            type = types.nullOr types.bool;
            default = null;

            description = ''
              Prepare this path in initrd, before NixOS activation.
            '';
          };

          configureParent = mkOption {
            type = types.nullOr types.bool;
            default = null;

            description = ''
              Create the parent directory on the persistent volume.
            '';
          };

          user = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          group = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          mode = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

        };
      }
    );

  persistence = types.submodule {
    options = {

      directories = mkOption {
        type = types.listOf (persistenceEntry "directory");
        default = [ ];

        description = ''
          Directories to preserve on this storage volume.
        '';
      };

      files = mkOption {
        type = types.listOf (persistenceEntry "file");
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

      stateRole = mkOption {
        type = types.str;
        default = "persist";

        description = ''
          Role of the volume that receives feature-declared
          persistence.state entries.
        '';
      };

      volumes = mkOption {
        type = types.attrsOf volume;
        default = { };

        description = ''
          Canonical volume definitions supplied by the layout.
        '';
      };

      persistence = mkOption {
        type = types.attrsOf persistence;
        default = { };

        description = ''
          Default persistence policy, merged with host policy.
        '';
      };

    };
  };

  model = types.submodule {
    options = {

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

            stateRole = mkOption {
              type = types.str;

              description = ''
                Role of the volume that receives persistence.state.
              '';
            };

          };
        };

        description = ''
          Metadata describing the selected storage layout.
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

      unassignedState = mkOption {
        type = types.nullOr persistence;
        default = null;

        description = ''
          Feature-declared persistence.state entries when no volume
          has the layout's stateRole. Reported by validation.
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

}
