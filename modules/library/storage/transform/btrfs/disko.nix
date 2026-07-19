_: {
  flake.library.storage.transform.btrfs.disko =
    {
      lib,
      ...
    }:

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
        encryption
        ;

      volumes = filterAttrs (_: volume: volume.mountpoint != null) model.volumes;

      subvolumes = mapAttrs' (
        _: volume:
        nameValuePair volume.name {
          mountpoint = volume.mountpoint;
        }
      ) volumes;

      filesystem = {
        type = "btrfs";

        subvolumes = subvolumes;
      };

      encryptedFilesystem =
        if encryption.enable then
          {
            type = "luks";

            name = encryption.label;

            settings = {
              allowDiscards = encryption.allowDiscards;
            };

            content = filesystem;
          }
        else
          filesystem;

    in

    {
      type = "disk";

      inherit device;

      content = {
        type = "gpt";

        partitions = {
          ESP = {
            size = "1G";

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
