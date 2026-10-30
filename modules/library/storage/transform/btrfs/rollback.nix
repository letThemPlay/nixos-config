{ config, lib, ... }:
{
  flake.library.storageTransformBtrfsRollback =
    let
      inherit (lib)
        concatMapStrings
        mkIf
        optionalString
        ;

      query = config.flake.library.storageQuery;
    in

    #
    # Produces boot.initrd.systemd configuration that recreates every
    # rollback volume from the template volume before /sysroot mounts.
    #
    # rootDevice is the btrfs block device from the disko transform.
    #
    {
      model,
      rootDevice,
      pkgs,
      utils,
    }:

    let
      volumes = query.rollback model;

      template = builtins.head (query.byCategory model "template");

      snapshotVolumes = query.byCategory model "snapshot";

      snapshotRoot = if snapshotVolumes == [ ] then null else builtins.head snapshotVolumes;

      inherit (model.rollback) keepSnapshots;

      deviceUnit = "${utils.escapeSystemdPath rootDevice}.device";

      #
      # Keep the previous generation as a read-only snapshot, then prune
      # all but the newest keepSnapshots entries.
      #
      archive =
        volume:
        let
          dir = ''"$mnt/${snapshotRoot.name}/rollback/${volume.id}"'';
        in
        optionalString (snapshotRoot != null && volume.snapshot && keepSnapshots > 0) ''
          mkdir -p ${dir}
          btrfs subvolume snapshot -r "$mnt/${volume.name}" ${dir}/"$stamp"
        '';

      prune =
        volume:
        let
          dir = ''"$mnt/${snapshotRoot.name}/rollback/${volume.id}"'';
        in
        optionalString (snapshotRoot != null && volume.snapshot && keepSnapshots > 0) ''
          find ${dir} -mindepth 1 -maxdepth 1 -printf '%f\n' \
            | sort \
            | head -n -${toString keepSnapshots} \
            | while read -r old; do
                btrfs subvolume delete ${dir}/"$old"
              done
        '';

      reset = volume: ''
        echo "storage-rollback: resetting ${volume.name}"

        if [ -d "$mnt/${volume.name}" ]; then
        ${archive volume}
          btrfs subvolume delete --recursive "$mnt/${volume.name}"
        fi

        btrfs subvolume snapshot "$mnt/${template.name}" "$mnt/${volume.name}"

        ${prune volume}
      '';

      script = pkgs.writeShellApplication {
        name = "storage-rollback";

        runtimeInputs = [
          pkgs.btrfs-progs
          pkgs.coreutils
          pkgs.findutils
          pkgs.util-linux
        ];

        text = ''
          mnt=/run/storage-rollback

          mkdir -p "$mnt"
          mount -t btrfs -o subvol=/ ${rootDevice} "$mnt"
          trap 'umount "$mnt"' EXIT

          # Never delete anything unless the template is present.
          if [ ! -d "$mnt/${template.name}" ]; then
            echo "storage-rollback: template ${template.name} missing, skipping" >&2
            exit 1
          fi

          stamp="$(date -u +%Y%m%dT%H%M%SZ)"

          ${concatMapStrings reset volumes}
        '';
      };

      active = volumes != [ ];

    in

    #
    # Keys are fixed and conditions sit inside mkIf: the module system
    # must know the attribute names before the model can be evaluated.
    #
    {
      enable = mkIf active true;

      storePaths = mkIf active [ script ];

      services.storage-rollback = mkIf active {
        description = "Reset ephemeral btrfs subvolumes from ${template.name}";

        wantedBy = [ "initrd.target" ];

        requires = [ deviceUnit ];

        after = [
          deviceUnit

          # Resuming from hibernation must see the untouched root.
          "systemd-hibernate-resume.service"
        ];

        before = [ "sysroot.mount" ];

        unitConfig.DefaultDependencies = false;

        serviceConfig = {
          Type = "oneshot";

          ExecStart = "${script}/bin/storage-rollback";
        };
      };
    };
}
