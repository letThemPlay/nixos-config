{ config, lib, ... }:
let
  storage = config.flake.factory.storage;

  inherit (config.flake.nixosModules) storage-api;

  #
  # Host settings are evaluated through the real API module so layout
  # defaults merge exactly as they do on a host.
  #
  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        storage-api
        {
          ohmydarlings.storage = {
            enable = true;
            disk = "/dev/disk/by-id/test";
          };
        }
        { ohmydarlings.storage = settings; }
      ];
    }).config.ohmydarlings.storage;

  modelOf = settings: storage.normalize (evalCfg settings);

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (storage.validate.all model).diagnostics);

  codes = settings: codesOf (modelOf settings);

  diskoOf = settings: storage.transform.btrfs.disko { model = modelOf settings; };

  subvolumesOf =
    settings:
    let
      root = (diskoOf settings).devices.disk.main.content.partitions.root.content;
    in
    (root.content or root).subvolumes;

  preservationOf = settings: storage.transform.btrfs.preservation { model = modelOf settings; };

  #
  # escapeSystemdPath is the only utils function the rollback uses.
  #
  rollbackOf =
    pkgs: settings:
    let
      model = modelOf settings;
    in
    storage.transform.btrfs.rollback {
      inherit model pkgs;
      inherit ((storage.transform.btrfs.disko { inherit model; })) rootDevice;
      utils = import "${pkgs.path}/nixos/lib/utils.nix" {
        inherit lib pkgs;
        config = { };
      };
    };

  noRootRollback = {
    volumes.root.rollback = false;
  };

  tests = pkgs: {

    #
    # normalize
    #

    testLayoutVolumes = {
      expr = lib.attrNames (modelOf { }).volumes;
      expected = [
        "blank"
        "home"
        "nix"
        "persist"
        "root"
        "snapshots"
      ];
    };

    testOverrideKeepsLayoutFields = {
      expr = {
        inherit ((modelOf { volumes.home.mountpoint = "/data"; }).volumes.home)
          mountpoint
          role
          category
          name
          ;
      };
      expected = {
        mountpoint = "/data";
        role = "home";
        category = "user";
        name = "@home";
      };
    };

    testBackendFromFilesystem = {
      expr = {
        inherit (modelOf { }) backend renderer;
      };
      expected = {
        backend = "btrfs";
        renderer = "disko";
      };
    };

    testDefaultPersistence = {
      expr = lib.elem "/var/log" (modelOf { }).persistence.persist.directories;
      expected = true;
    };

    testHostPersistenceExtendsDefaults = {
      expr =
        let
          dirs =
            (modelOf { persistence.policy.persist.directories = [ "/var/lib/extra" ]; })
            .persistence.persist.directories;
        in
        lib.all (dir: lib.elem dir dirs) [
          "/var/lib/extra"
          "/var/log"
        ];
      expected = true;
    };

    testUnknownLayoutIsMarked = {
      expr = (modelOf { layout = "nope"; }).layout.known;
      expected = false;
    };

    #
    # validate
    #

    testValidModel = {
      expr = codes { };
      expected = [ ];
    };

    testUnstableDiskWarns = {
      expr =
        (storage.validate.all (modelOf {
          disk = lib.mkForce "/dev/vda";
        })).warnings != [ ];
      expected = true;
    };

    testUnknownLayout = {
      expr = lib.elem "storage.layout.unknown" (codes {
        layout = "nope";
      });
      expected = true;
    };

    testPersistenceTargets = {
      expr = codes {
        persistence.policy = {
          root = { };
          nix = { };
          blank = { };
          bogus = { };
        };
      };
      expected = [
        "storage.persistence.volume.lateMount"
        "storage.persistence.volume.rollback"
        "storage.persistence.volume.unknown"
        "storage.persistence.volume.unmounted"
      ];
    };

    testRollbackTemplateMissing = {
      expr =
        let
          model = modelOf { };
        in
        codesOf (model // { volumes = removeAttrs model.volumes [ "blank" ]; });
      # blank is also a required role of the layout.
      expected = [
        "storage.role.missing"
        "storage.rollback.template.missing"
      ];
    };

    #
    # disko
    #

    testTemplateSubvolumeUnmounted = {
      expr = (subvolumesOf { })."@blank";
      expected = { };
    };

    testMountOptions = {
      expr = (subvolumesOf { volumes.persist.mountOptions = [ "nodev" ]; })."@persist".mountOptions;
      expected = [
        "compress=zstd"
        "noatime"
        "nodev"
      ];
    };

    testSwapfileUncompressed = {
      expr =
        (subvolumesOf {
          swap.enable = true;
          swap.size = "2G";
        })."@swap";
      expected = {
        mountpoint = "/.swapvol";
        mountOptions = [ "noatime" ];
        swap.swapfile.size = "2G";
      };
    };

    testNoSwapByDefault = {
      expr = (subvolumesOf { }) ? "@swap";
      expected = false;
    };

    testEspUmask = {
      expr = (diskoOf { }).devices.disk.main.content.partitions.ESP.content.mountOptions;
      expected = [ "umask=0077" ];
    };

    testRootDevicePlain = {
      expr = (diskoOf { }).rootDevice;
      expected = "/dev/disk/by-partlabel/disk-main-root";
    };

    testRootDeviceEncrypted = {
      expr = (diskoOf { encryption.enable = true; }).rootDevice;
      expected = "/dev/mapper/cryptroot";
    };

    testLuksPasswordFile = {
      expr =
        map (settings: (diskoOf settings).devices.disk.main.content.partitions.root.content ? passwordFile)
          [
            { encryption.enable = true; }
            {
              encryption.enable = true;
              encryption.passwordFile = "/tmp/key";
            }
          ];
      expected = [
        false
        true
      ];
    };

    #
    # preservation
    #

    testPreserveAtKeyedByMountpoint = {
      expr = lib.attrNames (preservationOf { }).preservation.preserveAt;
      expected = [ "/persist" ];
    };

    testUnsetSettingsStripped = {
      expr =
        lib.findFirst (entry: entry.directory or null == "/var/lib/nixos") null
          (preservationOf { }).preservation.preserveAt."/persist".directories;
      expected = {
        directory = "/var/lib/nixos";
        inInitrd = true;
      };
    };

    testEssentialsPreserved = {
      expr =
        let
          at = (preservationOf { }).preservation.preserveAt."/persist";
        in
        {
          machineId = lib.any (entry: entry.file or null == "/etc/machine-id") at.files;
          userborn = lib.any (entry: entry.directory or null == "/var/lib/userborn") at.directories;
        };
      expected = {
        machineId = true;
        userborn = true;
      };
    };

    testUserbornWithEphemeralRoot = {
      expr = {
        inherit ((preservationOf { }).services.userborn) condition;
        inherit ((preservationOf { }).services.userborn.content) passwordFilesLocation;
      };
      expected = {
        condition = true;
        passwordFilesLocation = "/var/lib/userborn";
      };
    };

    testNoEssentialsWithPersistentRoot = {
      expr = (preservationOf noRootRollback).services.userborn.condition;
      expected = false;
    };

    #
    # rollback
    #

    testRollbackOrdering = {
      expr = {
        inherit ((rollbackOf pkgs { }).services.storage-rollback.content) requires after before;
      };
      expected = {
        requires = [ "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device" ];
        after = [
          "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device"
          "systemd-hibernate-resume.service"
        ];
        before = [ "sysroot.mount" ];
      };
    };

    testRollbackEncryptedDevice = {
      expr = (rollbackOf pkgs { encryption.enable = true; }).services.storage-rollback.content.requires;
      expected = [ "dev-mapper-cryptroot.device" ];
    };

    testRollbackInactiveWithoutRollbackVolumes = {
      expr = (rollbackOf pkgs noRootRollback).services.storage-rollback.condition;
      expected = false;
    };

  };
in
{
  perSystem =
    { pkgs, ... }:
    let
      failures = lib.runTests (tests pkgs);
    in
    {
      checks.storage-lib =
        if failures == [ ] then
          pkgs.runCommand "storage-lib-tests" { } "touch $out"
        else
          throw "storage library tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
