{ pkgs, ... }: {
  config = {
    disko.enableConfig = true;

    boot.initrd.systemd = {
      enable = true;
      services.rollback = {
        description = "Rollback Btrfs root subvolume to pure blank state";
        wantedBy = [ "initrd-root-device.target" ];

        requires = [ "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2dbtrfs.device" ];
        after = [ "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2dbtrfs.device" ];

        before = [ "sysroot.mount" ];
        path = [
          pkgs.btrfs-progs
          pkgs.coreutils
          pkgs.util-linux
        ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "btrfs-rollback" ''
            TARGET_DEV="/dev/disk/by-partlabel/disk-main-btrfs"

            echo "IMPERMANENCE TRACK: Staging early storage environment..."
            mkdir -p /mnt
            mount -t btrfs -o subvol=/ "$TARGET_DEV" /mnt

            if [ $? -eq 0 ]; then
                if [ -e /mnt/@root ]; then
                    echo "IMPERMANENCE TRACK: Purging dirty untracked root files..."
                    btrfs subvolume delete /mnt/@root
                fi

                echo "IMPERMANENCE TRACK: Re-cloning fresh stateless root subvolume canvas..."
                btrfs subvolume snapshot /mnt/@blank /mnt/@root
                
                umount /mnt
                echo "IMPERMANENCE TRACK: Reset sequence finished successfully."
            else
                echo "CRITICAL ERROR: Failed to mount the top-level Btrfs volume root!"
                exit 1
            fi
          '';
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
