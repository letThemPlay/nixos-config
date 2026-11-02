{ config, inputs, ... }:
let
  storage = config.ltp.features.storage;

  inherit (config.flake.nixosModules) storage-options;

  storageModule = config.flake.nixosModules.storage;

  inherit (config.flake.nixosModules) identity-options;

  identityModule = config.flake.nixosModules.identity;

  settings = {
    enable = true;

    disk = "/dev/vda";

    # The test disks are 4 GiB.
    boot.efiSize = "256M";

    swap.enable = true;
    swap.size = "64M";

    rollback.keepSnapshots = 2;
  };

  # yescrypt hash of "hunter2"
  passwordHash = "$y$j9T$zuHINQgFvURdfqnHLteY0/$5CJ5oLmXc8UVg5ys2dSVX5LBVWWlVAiW6o2SDOiiLY4";
in
{
  perSystem =
    { pkgs, lib, ... }:
    let
      cfg =
        (lib.evalModules {
          modules = [
            storage-options
            { ltp.storage = settings; }
          ];
        }).config.ltp.storage;

      disko = storage.backends.btrfs.disko { model = storage.normalize cfg; };

      #
      # disko's test library still reads boot.initrd.systemd.enable,
      # which nixpkgs removed with the scripted initrd (systemd initrd is
      # the only one). Patched until disko catches up; --replace-fail
      # breaks the build once upstream changes these lines, as a
      # reminder to drop this.
      #
      diskoPatched = pkgs.applyPatches {
        name = "disko-systemd-initrd";
        src = inputs.disko;
        postPatch = ''
          substituteInPlace lib/tests.nix \
            --replace-fail 'lib.mkIf (!config.boot.initrd.systemd.enable)' 'lib.mkIf false' \
            --replace-fail 'lib.mkIf config.boot.initrd.systemd.enable' 'lib.mkIf true' \
            --replace-fail '../module.nix' '${inputs.disko}/module.nix'
        '';
      };

      inherit
        (import (diskoPatched + "/lib") {
          inherit lib;
          makeTest = import (inputs.nixpkgs + "/nixos/tests/make-test-python.nix");
          eval-config = import (inputs.nixpkgs + "/nixos/lib/eval-config.nix");
          qemu-common = import (inputs.nixpkgs + "/nixos/lib/qemu-common.nix");
        })
        testLib
        ;
    in
    {
      #
      # Formats the disk, installs a minimal system and boots it three
      # times to exercise rollback, preservation and snapshot pruning.
      #
      # Kept out of `checks` because it takes several minutes; run with
      #   nix build .#vmTests.storage
      #
      legacyPackages.vmTests.storage = testLib.makeDiskoTest {
        inherit pkgs;

        name = "storage";

        disko-config = {
          disko.devices = disko.devices;
        };

        extraSystemConfig = {
          imports = [
            storage-options
            storageModule
            identity-options
            identityModule
          ];

          ltp.storage = settings // {
            #
            # Stand-ins for what features declare: a state directory and
            # the SSH host key (the secrets feature is not part of this
            # minimal system).
            #
            persistence.state = {
              directories = [ "/var/lib/feature-state" ];

              files =
                map
                  (file: {
                    inherit file;
                    how = "symlink";
                    inInitrd = true;
                    configureParent = true;
                  })
                  [
                    "/etc/ssh/ssh_host_ed25519_key"
                    "/etc/ssh/ssh_host_ed25519_key.pub"
                  ];
            };
          };

          services.openssh.enable = true;

          # Her password file is derived: /persist/secrets/passwords/alice.
          ltp.identity.users.alice = {
            fullName = "Alice";
            email = "alice@example.com";
            admin = true;
            enable = true;
          };
        };

        postDisko = ''
          machine.succeed("mkdir -p /mnt/persist/secrets/passwords")
          machine.succeed("echo '${passwordHash}' > /mnt/persist/secrets/passwords/alice")
          machine.succeed("chmod 0400 /mnt/persist/secrets/passwords/alice")
        '';

        extraTestScript = ''
          # create_test_machine reads the disk images from the state
          # directory of the machine it is given, which is always the
          # original installer node.
          installer = next(m for m in driver.machines_qemu if m.name == "machine")

          def reboot(old, name):
              old.shutdown()
              new = create_test_machine(oldmachine=installer, name=name)
              new.start()
              new.wait_for_unit("multi-user.target")
              return new

          def snapshots(m):
              return int(m.succeed("ls /.snapshots/rollback/root | wc -l").strip())

          machine.wait_for_unit("multi-user.target")
          # sshd-keygen is a oneshot without RemainAfterExit; wait for its
          # output to land on the persist volume instead.
          machine.wait_until_succeeds("test -s /persist/etc/ssh/ssh_host_ed25519_key.pub")

          with subtest("root is the freshly reset @root subvolume"):
              machine.succeed("findmnt -no OPTIONS / | grep -q 'subvol=/@root'")
              assert snapshots(machine) == 1, "first boot should archive the installed root"

          with subtest("state is linked to /persist"):
              machine.succeed("test -L /etc/machine-id")
              machine.succeed("test -L /etc/ssh/ssh_host_ed25519_key")
              machine.succeed("findmnt /var/log")
              machine.succeed("findmnt /var/lib/userborn")
              machine.succeed("findmnt /var/lib/feature-state")

          with subtest("userborn reads the password hash from /persist"):
              machine.succeed("grep -qF 'alice:${passwordHash}:' /etc/shadow")

          with subtest("swapfile is active"):
              machine.succeed("swapon --show=NAME --noheadings | grep -q /.swapvol/swapfile")

          machine_id = machine.succeed("cat /etc/machine-id").strip()
          host_key = machine.succeed("cat /etc/ssh/ssh_host_ed25519_key.pub").strip()
          assert len(machine_id) == 32, f"machine-id not committed: {machine_id!r}"

          machine.succeed("touch /etc/ephemeral-marker /persist/persist-marker /home/home-marker /var/log/log-marker /var/lib/feature-state/marker")
          machine.succeed("sync")

          machine = reboot(machine, "second_boot")

          with subtest("root was reset, previous root archived"):
              machine.fail("test -e /etc/ephemeral-marker")
              assert snapshots(machine) == 2
              newest = machine.succeed("ls /.snapshots/rollback/root | sort | tail -n 1").strip()
              machine.succeed(f"test -e /.snapshots/rollback/root/{newest}/etc/ephemeral-marker")

          with subtest("persistent data survived"):
              machine.succeed("test -e /persist/persist-marker")
              machine.succeed("test -e /home/home-marker")
              machine.succeed("test -e /var/log/log-marker")
              machine.succeed("test -e /var/lib/feature-state/marker")

          with subtest("identity is stable"):
              assert machine.succeed("cat /etc/machine-id").strip() == machine_id
              assert machine.succeed("cat /etc/ssh/ssh_host_ed25519_key.pub").strip() == host_key
              machine.succeed("grep -q '^alice:' /etc/shadow")

          machine = reboot(machine, "third_boot")

          with subtest("old snapshots are pruned to keepSnapshots"):
              assert snapshots(machine) == 2
        '';
      };
    };
}
