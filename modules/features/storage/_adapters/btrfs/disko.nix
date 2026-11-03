{ lib }:
{ model }:

let
  inherit (lib)
    filterAttrs
    mapAttrs'
    nameValuePair
    optionalAttrs
    optionals
    ;

  inherit (model.platform)
    boot
    encryption
    filesystem
    labels
    swap
    ;

  #
  # disko derives partition labels as "disk-<disk>-<partition>".
  #
  diskName = "main";
  partitionName = "root";

  byLabel = label: "/dev/disk/by-label/${label}";

  #
  # Block device holding the btrfs filesystem once unlocked.
  # Consumed by the rollback transform.
  #
  rootDevice =
    if labels.enable then
      byLabel labels.root
    else if encryption.enable then
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
    ]
    ++ optionals labels.enable [
      "-L"
      labels.root
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
      // optionalAttrs labels.enable {
        extraFormatArgs = [
          "--label"
          encryption.label
        ];
      }
    else
      btrfsFilesystem;

  #
  # disko formats through the partlabels and generates its mounts from
  # them; the filesystem labels only exist once mkfs has run, so they
  # can't be disko's devices. The storage module forces these onto the
  # generated fileSystems and LUKS device instead.
  #
  mounts = optionalAttrs labels.enable (
    {
      "/boot" = byLabel labels.boot;
    }
    // mapAttrs' (_: subvolume: nameValuePair subvolume.mountpoint (byLabel labels.root)) (
      filterAttrs (_: subvolume: subvolume ? mountpoint) (subvolumes // swapSubvolume)
    )
  );

  luksDevice = if labels.enable && encryption.enable then byLabel encryption.label else null;

in
{
  inherit rootDevice mounts luksDevice;

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

            extraArgs = optionals labels.enable [
              "-n"
              labels.boot
            ];
          };
        };

        ${partitionName} = {
          size = "100%";

          content = encryptedFilesystem;
        };

      };
    };
  };
}
