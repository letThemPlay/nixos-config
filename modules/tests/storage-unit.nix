{ config, lib, ... }:
let
  storage = config.flake.features.storage;

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
          ltp.storage = {
            enable = true;
            disk = "/dev/disk/by-id/test";
          };
        }
        { ltp.storage = settings; }
      ];
    }).config.ltp.storage;

  modelOf = settings: storage.normalize (evalCfg settings);

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (storage.validate.all model).diagnostics);

  codes = settings: codesOf (modelOf settings);

  diskoOf = settings: storage.backends.btrfs.disko { model = modelOf settings; };

  subvolumesOf =
    settings:
    let
      root = (diskoOf settings).devices.disk.main.content.partitions.root.content;
    in
    (root.content or root).subvolumes;

  preservationOf = settings: storage.preservation { model = modelOf settings; };

  #
  # escapeSystemdPath is the only utils function the rollback uses.
  #
  rollbackOf =
    pkgs: settings:
    let
      model = modelOf settings;
    in
    storage.backends.btrfs.rollback {
      inherit model pkgs;
      inherit ((storage.backends.btrfs.disko { inherit model; })) rootDevice;
      utils = import "${pkgs.path}/nixos/lib/utils.nix" {
        inherit lib pkgs;
        config = { };
      };
    };

  noRootRollback = {
    volumes.root.rollback = false;
  };

  # Settings covering the optional parts of the model.
  contractCases = [
    { }
    noRootRollback
    {
      swap.enable = true;
      encryption.enable = true;
      volumes.data.mountpoint = "/data";
      persistence.policy.persist.files = [ "/etc/extra" ];
      persistence.state.directories = [
        {
          directory = "/var/lib/feature";
          mode = "0700";
        }
      ];
    }
    {
      # unassignedState populated
      volumes.persist.role = "other";
      persistence.state.directories = [ "/var/lib/feature" ];
    }
  ];

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
      expr = (modelOf { }).backend;
      expected = "btrfs";
    };

    #
    # backend registry
    #

    testBackendRegistry = {
      expr = lib.mapAttrs (_: backend: lib.attrNames backend) storage.backends;
      expected.btrfs = [
        "disko"
        "rollback"
      ];
    };

    # A selector is a string, so a bad name reaches validation.
    testUnknownBackend = {
      expr = codes { backend = "zfs"; };
      expected = [ "storage.backend.unknown" ];
    };

    testUnknownVolumeBackend = {
      expr = codes { volumes.home.backend = "zfs"; };
      expected = [ "storage.volume.backend.unknown" ];
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

    # normalize is a plain function: no module system needed, and it
    # agrees with the result through the NixOS options.
    testNormalizeWithoutModuleSystem = {
      expr =
        let
          plain = storage.normalize {
            layout = "erase-my-darlings";
            disk = "/dev/disk/by-id/test";
            backend = "btrfs";
            filesystem.compression = "zstd";
            boot.efiSize = "1G";
            swap = {
              enable = false;
              size = "1G";
            };
            encryption = {
              enable = false;
              label = "cryptroot";
              allowDiscards = true;
              passwordFile = null;
            };
            rollback.keepSnapshots = 5;
            volumes.home.mountpoint = "/data";
            persistence = {
              defaultPolicy = true;
              policy = { };
              state = {
                directories = [ ];
                files = [ ];
              };
            };
          };

          viaOptions = modelOf { volumes.home.mountpoint = "/data"; };
        in
        {
          volumes = plain.volumes == viaOptions.volumes;
          persistence = plain.persistence == viaOptions.persistence;
          home = plain.volumes.home.mountpoint;
        };
      expected = {
        volumes = true;
        persistence = true;
        home = "/data";
      };
    };

    testOverrideAddsNewVolume = {
      expr = {
        inherit ((modelOf { volumes.data.mountpoint = "/data"; }).volumes.data)
          role
          name
          category
          mountpoint
          ;
      };
      expected = {
        role = "data";
        name = "@data";
        category = "state";
        mountpoint = "/data";
      };
    };

    # The documented model type is the contract between normalize and
    # its consumers: every normalized model must type-check against it.
    testModelContract = {
      expr = map (
        settings:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = storage.types.model; }; }
                { model = modelOf settings; }
              ];
            }).config.model;
        in
        builtins.deepSeq checked true
      ) contractCases;
      expected = map (_: true) contractCases;
    };

    testUnsupportedLayoutVersion = {
      expr =
        let
          model = modelOf { };
        in
        codesOf (
          model
          // {
            layout = model.layout // {
              version = 2;
            };
          }
        );
      expected = [ "storage.layout.version.unsupported" ];
    };

    testLayoutDefaultsCanBeDisabled = {
      expr =
        (modelOf {
          persistence.defaultPolicy = false;
          persistence.policy.persist.directories = [ "/var/lib/only" ];
        }).persistence.persist.directories;
      expected = [ "/var/lib/only" ];
    };

    # Layouts are plain data; check them against the entity type.
    testLayoutsTypeCheck = {
      expr = lib.mapAttrs (
        _: layout:
        let
          evaluated =
            (lib.evalModules {
              modules = [
                { options.layout = lib.mkOption { type = storage.types.layout; }; }
                { inherit layout; }
              ];
            }).config.layout;
        in
        builtins.deepSeq evaluated true
      ) storage.layouts;
      expected = lib.mapAttrs (_: _: true) storage.layouts;
    };

    testStateRoutedToStateVolume = {
      expr =
        let
          model = modelOf {
            persistence.state = {
              directories = [ "/var/lib/feature" ];
              files = [ "/etc/feature.conf" ];
            };
          };
        in
        {
          directory = lib.elem "/var/lib/feature" model.persistence.persist.directories;
          file = lib.elem "/etc/feature.conf" model.persistence.persist.files;
          keepsLayoutDefaults = lib.elem "/var/log" model.persistence.persist.directories;
          inherit (model) unassignedState;
        };
      expected = {
        directory = true;
        file = true;
        keepsLayoutDefaults = true;
        unassignedState = null;
      };
    };

    testEmptyStateLeavesModelUnchanged = {
      expr = (modelOf { }).unassignedState;
      expected = null;
    };

    testStateWithoutStateVolumeIsReported = {
      expr = lib.elem "storage.persistence.state.unassigned" (codes {
        volumes.persist.role = "other";
        persistence.state.directories = [ "/var/lib/feature" ];
      });
      expected = true;
    };

    #
    # query: derived facts
    #

    testDerivedFacts = {
      expr =
        let
          model = modelOf { };
        in
        {
          stateVolume = (storage.query.stateVolume model).id;
          template = (storage.query.template model).id;
          snapshotVolume = (storage.query.snapshotVolume model).id;
          ephemeralRoot = storage.query.ephemeralRoot model;
          luksName = storage.query.luksName model;
        };
      expected = {
        stateVolume = "persist";
        template = "blank";
        snapshotVolume = "snapshots";
        ephemeralRoot = true;
        luksName = null;
      };
    };

    testEncryptedLuksName = {
      expr = storage.query.luksName (modelOf {
        encryption.enable = true;
      });
      expected = "cryptroot";
    };

    testPersistentRootIsNotEphemeral = {
      expr = storage.query.ephemeralRoot (modelOf noRootRollback);
      expected = false;
    };

    testNoStateVolume = {
      expr = storage.query.stateVolume (modelOf {
        volumes.persist.role = "other";
      });
      expected = null;
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
        "storage.persistence.volume.late"
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

    # Overrides apply the fields they define, so a nullable field can be
    # set to null on purpose.
    testExplicitNullOverride = {
      expr = {
        unmounted = (modelOf { volumes.home.mountpoint = null; }).volumes.home.mountpoint;
        untouched = (modelOf { volumes.home.snapshot = false; }).volumes.home.mountpoint;
      };
      expected = {
        unmounted = null;
        untouched = "/home";
      };
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
      expr = lib.attrNames (preservationOf { }).preserveAt;
      expected = [ "/persist" ];
    };

    testUnsetSettingsStripped = {
      expr =
        lib.findFirst (entry: entry.directory or null == "/var/lib/nixos") null
          (preservationOf { }).preserveAt."/persist".directories;
      expected = {
        directory = "/var/lib/nixos";
        inInitrd = true;
      };
    };

    # Plain data only; identity and user policy live in the
    # identity feature.
    testPreservationIsPlainData = {
      expr = lib.attrNames (preservationOf { });
      expected = [ "preserveAt" ];
    };

    testRollbackIsPlainData = {
      expr = lib.attrNames (rollbackOf pkgs { });
      expected = [
        "active"
        "script"
        "service"
      ];
    };

    testFeatureStateRendered = {
      # Plain path entries are passed through as strings.
      expr =
        lib.elem "/var/lib/feature"
          (preservationOf {
            persistence.state.directories = [ "/var/lib/feature" ];
          }).preserveAt."/persist".directories;
      expected = true;
    };

    #
    # rollback
    #

    testRollbackOrdering = {
      expr = {
        inherit ((rollbackOf pkgs { }).service) requires after before;
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
      expr = (rollbackOf pkgs { encryption.enable = true; }).service.requires;
      expected = [ "dev-mapper-cryptroot.device" ];
    };

    testRollbackInactiveWithoutRollbackVolumes = {
      expr = (rollbackOf pkgs noRootRollback).active;
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
      checks.storage-unit =
        if failures == [ ] then
          pkgs.runCommand "storage-unit-tests" { } "touch $out"
        else
          throw "storage unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
