{ config, ... }:
let
  storage = config.flake.library.storage;
in
{
  flake.nixosModules.storage-api =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib)
        mapAttrs
        mkDefault
        mkEnableOption
        mkIf
        mkOption
        types
        ;

      cfg = config.ohmydarlings.storage;

      #
      # Layout volumes are injected as mkDefault definitions so hosts
      # override individual fields instead of whole volumes.
      #
      # An unknown layout contributes no volumes; validation reports it.
      #
      layoutVolumes = storage.layouts.${cfg.layout}.volumes or { };

      #
      # Layout persistence is merged at normal priority so host entries
      # extend the defaults. Use mkForce on a list to replace it.
      #
      layoutPersistence = storage.layouts.${cfg.layout}.persistence or { };
    in
    {
      options.ohmydarlings.storage = {

        enable = mkEnableOption "Oh My Darlings storage subsystem";

        renderer = mkOption {
          type = types.enum [ "disko" ];
          default = "disko";

          description = ''
            Tool that renders the storage model into host configuration.

            The filesystem backend is selected by filesystem.type.
          '';
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

        passwordDirectory = mkOption {
          type = types.nullOr types.str;
          default = null;

          example = "/persist/secrets/passwords";

          description = ''
            Directory holding one hashed password file per user profile,
            named after the user (create with `mkpasswd -m yescrypt`).

            Only used when the root volume is rolled back. Defaults to
            secrets/passwords on the persist volume. It must live on a
            volume mounted in initrd: userborn runs before agenix
            decrypts secrets.
          '';
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

        filesystem = {

          type = mkOption {
            type = storage.types.backend;
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

            Defaults to the volumes of the selected layout. Individual
            fields may be overridden per host.

            Storage backends consume this model to produce
            backend-specific configuration.
          '';
        };

        persistence = {

          policy = mkOption {
            type = types.attrsOf storage.types.persistence;

            default = { };

            description = ''
              Persistence policy grouped by storage volume identifier.

              Each attribute name must refer to a volume defined in
              storage.volumes.
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
              `lib.mkIf config.ohmydarlings.storage.enable { ... }`.
            '';
          };

        };
      };

      config = mkIf cfg.enable {
        ohmydarlings.storage.volumes = mapAttrs (_: mapAttrs (_: mkDefault)) layoutVolumes;

        ohmydarlings.storage.persistence.policy = layoutPersistence;
      };
    };
}
