{ pkgs, ... }: {
  config = {
    disko.enableConfig = true;

    boot.zfs.forceImportRoot = false;

    boot.initrd.systemd = {
      enable = true;
      services.rollback = {
        description = "Rollback ZFS root dataset to blank stateless snapshot";
        wantedBy = [ "initrd-root-device.target" ];
        after = [ "zfs-import-zpool.service" ];
        before = [ "sysroot.mount" ];
        path = [ pkgs.zfs ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.zfs}/bin/zfs rollback -r zpool/root@blank";
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
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "zpool";
                };
              };
            };
          };
        };
      };
      zpool = {
        main = {
          type = "zpool";
          mountpoint = null;

          datasets = {
            root = {
              type = "zfs_fs";
              mountpoint = "/";
              options = {
                "com.sun:auto-snapshot" = "false";
                mountpoint = "legacy";
              };
              postCreateHook = "zfs snapshot zpool/root@blank";
            };

            persist = {
              type = "zfs_fs";
              mountpoint = "/persist";
              options = {
                "com.sun:auto-snapshot" = "true";
                mountpoint = "legacy";
              };
            };

            nix = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options = {
                atime = "off";
                "com.sun:auto-snapshot" = "false";
                mountpoint = "legacy";
              };
            };
          };
        };
      };
    };
  };
}
