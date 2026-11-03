{ config, ... }:
let
  storage = config.ltp.features.storage;
in
{
  #
  # Options only. Merging the layout with host settings is a domain rule
  # and happens in normalize.
  #
  flake.nixosModules.storage-options =
    { lib, ... }:
    let
      inherit (lib)
        mkEnableOption
        mkOption
        types
        ;
    in
    {
      options.ltp.storage = {

        enable = mkEnableOption "Oh My Darlings storage feature";

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

          passwordFile = mkOption {
            type = types.nullOr types.str;
            default = null;

            example = "/tmp/secret.key";

            description = ''
              File containing the LUKS passphrase, read only while
              formatting. When null, disko prompts interactively.
            '';
          };

        };

        #
        # Labels decouple the installed system from the disk's name:
        # disko writes them while formatting and every mount, the LUKS
        # unlock and the rollback then find their device by label. The
        # disk path is then only read by disko, so a plain /dev/nvme0n1
        # is fine.
        #
        labels = {

          enable = mkEnableOption "filesystem labels written by disko and used for mounting";

          boot = mkOption {
            type = types.str;
            default = "BOOT";

            description = ''
              Label of the EFI system partition's vfat filesystem, at
              most 11 characters.
            '';
          };

          root = mkOption {
            type = types.str;
            default = "nixos";

            description = ''
              Label of the btrfs filesystem. The LUKS header, when
              encrypted, is labelled with encryption.label.
            '';
          };

        };

        #
        # Read-only facts derived from the model, published for other
        # features. They depend only on volumes and platform settings,
        # never on persistence, so features may use them in conditions
        # on persistence.state.
        #
        facts = {

          ephemeralRoot = mkOption {
            type = types.bool;
            readOnly = true;

            description = ''
              Whether / is recreated on every boot. Set by the storage
              module; false when storage is disabled.
            '';
          };

          statePath = mkOption {
            type = types.nullOr types.str;
            readOnly = true;

            example = "/persist";

            description = ''
              Mountpoint of the volume that receives persistence.state,
              or null when there is none or storage is disabled.
            '';
          };

          luksName = mkOption {
            type = types.nullOr types.str;
            readOnly = true;

            example = "cryptroot";

            description = ''
              LUKS mapping that holds the root filesystem, or null when
              it is unencrypted or storage is disabled.
            '';
          };

        };

        rollback = {

          keepSnapshots = mkOption {
            type = types.ints.unsigned;
            default = 5;

            description = ''
              Number of pre-rollback snapshots kept per volume under the
              snapshots volume. 0 disables archiving.
            '';
          };

        };

        backend = mkOption {
          type = types.str;
          default = "btrfs";

          description = ''
            Storage backend that renders the volumes (see
            ltp.features.storage.backends).
          '';
        };

        filesystem = {

          compression = mkOption {
            type = types.str;
            default = "zstd";
          };

        };

        volumes = mkOption {
          type = types.attrsOf storage.types.volumeOverride;

          default = { };

          example = {
            home.mountpoint = "/data";
          };

          description = ''
            Per-host volume overrides, merged over the selected layout's
            volumes. Only fields that are set replace the layout value;
            an attribute that is not in the layout adds a new volume.
          '';
        };

        persistence = {

          defaultPolicy = mkOption {
            type = types.bool;
            default = true;

            description = ''
              Whether the layout's default persistence policy is
              included. Host policy and feature-declared state are
              always added.
            '';
          };

          policy = mkOption {
            type = types.attrsOf storage.types.persistence;

            default = { };

            description = ''
              Host persistence policy grouped by storage volume
              identifier, added to the layout's default policy.

              Each attribute name must refer to a volume of the model.
            '';
          };

          state = mkOption {
            type = storage.types.persistence;

            default = { };

            example = {
              directories = [ "/var/lib/bluetooth" ];
            };

            description = ''
              State a feature needs to survive reboots, without naming a
              volume. Merged into the volume whose role is the layout's
              stateRole ("persist" for erase-my-darlings).

              Features should set this only when storage is enabled:
              `lib.mkIf config.ltp.storage.enable { ... }`.
            '';
          };

        };
      };
    };
}
