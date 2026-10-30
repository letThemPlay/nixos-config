{ lib, ... }:
{
  flake.library.storageTransformBtrfsDisko =
    { model }:

    let
      inherit (lib)
        filterAttrs
        mapAttrs'
        nameValuePair
        optionalAttrs
        ;

      inherit (model.platform)
        boot
        encryption
        filesystem
        swap
        ;

      #
      # disko derives partition labels as "disk-<disk>-<partition>".
      #
      diskName = "main";
      partitionName = "root";

      #
      # Block device holding the btrfs filesystem once unlocked.
      # Consumed by the rollback transform.
      #
      rootDevice =
        if encryption.enable then
          "/dev/mapper/${encryption.label}"
        else
          "/dev/disk/by-partlabel/disk-${diskName}-${partitionName}";

      defaultMountOptions = [
        "compress=${filesystem.compression}"
        "noatime"
      ];

      volumes = filterAttrs (_: volume: volume.backend == "btrfs") model.volumes;

      #
      # Every volume becomes a subvolume. Unmounted volumes such as the
      # rollback template are created but not mounted.
      #
      subvolumes = mapAttrs' (
        _: volume:
        nameValuePair volume.name (
          optionalAttrs (volume.mountpoint != null) {
            inherit (volume) mountpoint;

            mountOptions = defaultMountOptions ++ volume.mountOptions;
          }
        )
      ) volumes;

      #
      # Swapfiles must not be compressed, so the swap subvolume skips
      # the default mount options. disko creates the file NOCOW and
      # registers it in swapDevices.
      #
      swapSubvolume = optionalAttrs swap.enable {
        "@swap" = {
          mountpoint = "/.swapvol";

          mountOptions = [ "noatime" ];

          swap.swapfile.size = swap.size;
        };
      };

      btrfsFilesystem = {
        type = "btrfs";

        subvolumes = subvolumes // swapSubvolume;

        extraArgs = [
          "-f"
        ];
      };

      encryptedFilesystem =
        if encryption.enable then
          {
            type = "luks";

            name = encryption.label;

            settings = {
              inherit (encryption) allowDiscards;
            };

            content = btrfsFilesystem;
          }
          // optionalAttrs (encryption.passwordFile != null) {
            inherit (encryption) passwordFile;
          }
        else
          btrfsFilesystem;

    in
    {
      inherit rootDevice;

      devices.disk.${diskName} = {
        type = "disk";

        device = model.platform.disk;

        content = {
          type = "gpt";

          partitions = {

            ESP = {
              size = boot.efiSize;

              type = "EF00";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";

                mountOptions = [ "umask=0077" ];
              };
            };

            ${partitionName} = {
              size = "100%";

              content = encryptedFilesystem;
            };

          };
        };
      };
    };
}
