{ pkgs, ... }: {
  config = {
    disko.enableConfig = true;

    boot.initrd.systemd = {
      enable = true;

      storePaths = [
        "${pkgs.btrfs-progs}/bin/btrfs"
        "${pkgs.coreutils}/bin/mkdir"
        "${pkgs.util-linux}/bin/mount"
        "${pkgs.util-linux}/bin/umount"
      ];

      services.rollback = {
        description = "Rollback Btrfs root subvolume to pure blank state";
        wantedBy = [ "initrd-root-device.target" ];

        requires = [ "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2dbtrfs.device" ];
        after = [ "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2dbtrfs.device" ];

        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";

        path = [
          pkgs.btrfs-progs
          pkgs.coreutils
          pkgs.util-linux
        ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = [
            "${pkgs.coreutils}/bin/mkdir -p /mnt"
            "${pkgs.util-linux}/bin/mount -t btrfs -o subvol=/ /dev/disk/by-partlabel/disk-main-btrfs /mnt"

            "/bin/sh -c 'if [ -e /mnt/@root ]; then \
               ${pkgs.btrfs-progs}/bin/btrfs subvolume list -o /mnt/@root | \
               ${pkgs.coreutils}/bin/cut -f 9- -d \" \" | \
               while read -r subvol; do \
                 ${pkgs.btrfs-progs}/bin/btrfs subvolume delete \"/mnt/$subvol\"; \
               done; \
               ${pkgs.btrfs-progs}/bin/btrfs subvolume delete /mnt/@root; \
             fi'"

            "${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot /mnt/@blank /mnt/@root"
            "${pkgs.util-linux}/bin/umount /mnt"
          ];
        };
      };
    };

    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/nvme0n1";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              btrfs = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@blank" = { };
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
