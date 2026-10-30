_: {
  flake.library.storageLayouts = {

    erase-my-darlings = {

      version = 1;

      description = ''
        Ephemeral root filesystem with persistent system state,
        user data and Nix store.
      '';

      requiredRoles = [
        "root"
        "blank"
        "persist"
        "nix"
        "home"
        "snapshots"
      ];

      volumes = {

        root = {
          role = "root";
          category = "system";

          backend = null;

          name = "@root";

          mountpoint = "/";

          neededForBoot = true;
          snapshot = true;
          rollback = true;
        };

        blank = {
          role = "blank";
          category = "template";

          backend = null;

          name = "@blank";

          mountpoint = null;

          neededForBoot = false;
          snapshot = false;
          rollback = false;
        };

        persist = {
          role = "persist";
          category = "state";

          backend = null;

          name = "@persist";

          mountpoint = "/persist";

          neededForBoot = true;
          snapshot = true;
          rollback = false;
        };

        nix = {
          role = "nix";
          category = "store";

          backend = null;

          name = "@nix";

          mountpoint = "/nix";

          neededForBoot = false;
          snapshot = false;
          rollback = false;
        };

        home = {
          role = "home";
          category = "user";

          backend = null;

          name = "@home";

          mountpoint = "/home";

          neededForBoot = false;
          snapshot = true;
          rollback = false;
        };

        snapshots = {
          role = "snapshots";
          category = "snapshot";

          backend = null;

          name = "@snapshots";

          mountpoint = "/.snapshots";

          neededForBoot = false;
          snapshot = false;
          rollback = false;
        };

      };

      #
      # System state that must survive the root rollback.
      #
      # /home is its own persistent volume and needs no entries.
      # machine-id and user database plumbing is added by the
      # preservation transform.
      #
      persistence = {

        persist = {

          directories = [
            "/var/log"
            "/var/lib/bluetooth"
            "/var/lib/NetworkManager"
            "/etc/secureboot"
            "/var/lib/systemd/coredump"
            "/var/lib/systemd/rfkill"
            "/var/lib/systemd/timers"

            {
              directory = "/var/lib/nixos";
              inInitrd = true;
            }
          ];

          files =
            #
            # Host keys are symlinked in initrd so agenix can decrypt
            # secrets during activation.
            #
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
                "/etc/ssh/ssh_host_rsa_key"
                "/etc/ssh/ssh_host_rsa_key.pub"
              ]

            ++ [
              {
                file = "/var/lib/systemd/random-seed";
                how = "symlink";
                inInitrd = true;
                configureParent = true;
              }
            ];

        };

      };

    };

  };
}
