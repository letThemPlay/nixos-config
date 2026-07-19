_: {
  flake.library.storage.layouts = {

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

    };

  };
}
