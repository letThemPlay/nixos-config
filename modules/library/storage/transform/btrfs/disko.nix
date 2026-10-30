{ lib, ... }:
{
  flake.library.storageTransformBtrfsDisko =
    input:

    let
      inherit (lib)
        filterAttrs
        mapAttrs'
        nameValuePair
        ;

      inherit (input)
        model
        device
        boot
        encryption
        filesystem
        ;

      volumes = filterAttrs (_: volume: volume.mountpoint != null) model.volumes;

      subvolumes = mapAttrs' (
        _: volume:
        nameValuePair volume.name {
          mountpoint = volume.mountpoint;
        }
      ) volumes;

      btrfsFilesystem = {
        type = "btrfs";

        subvolumes = subvolumes;

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
              allowDiscards = encryption.allowDiscards;
            };

            content = btrfsFilesystem;
          }
        else
          btrfsFilesystem;

    in
    {
      type = "disk";

      inherit device;

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
            };
          };

          root = {
            size = "100%";

            content = encryptedFilesystem;
          };

        };
      };
    };
}
