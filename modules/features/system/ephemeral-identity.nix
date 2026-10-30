_: {
  #
  # Machine identity and user database on an ephemeral root.
  #
  # When the storage subsystem recreates / on every boot, /etc is lost
  # with it. This feature keeps the machine-id, preserves the userborn
  # user database and makes users declarative. It only reads the
  # published storage facts and declares its state like any feature.
  #
  flake.nixosModules.ephemeral-identity =
    { config, lib, ... }:
    let
      inherit (lib) mkIf mkOption types;

      inherit (config.ohmydarlings.storage) facts;

      active = facts.ephemeralRoot && facts.statePath != null;

      userbornState = "/var/lib/userborn";
    in
    {
      options.ohmydarlings.identity.passwordDirectory = mkOption {
        type = types.nullOr types.str;

        default = if active then "${facts.statePath}/secrets/passwords" else null;

        defaultText = lib.literalExpression ''"''${config.ohmydarlings.storage.facts.statePath}/secrets/passwords" on an ephemeral root, otherwise null'';

        description = ''
          Directory holding one hashed password file per user profile,
          named after the user (create with `mkpasswd -m yescrypt`).

          It must live on a volume mounted in initrd: userborn creates
          users before agenix decrypts secrets.
        '';
      };

      config = mkIf active {

        ohmydarlings.storage.persistence.state = {
          directories = [
            {
              directory = userbornState;
              inInitrd = true;
            }
          ];

          files = [
            {
              file = "/etc/machine-id";
              how = "symlink";
              inInitrd = true;
              configureParent = true;
            }
          ];
        };

        #
        # userborn keeps passwd, group and shadow in its preserved state
        # directory and links them into /etc.
        #
        services.userborn = {
          enable = true;

          passwordFilesLocation = userbornState;
        };

        #
        # First boot: seed the persistent machine-id as "uninitialized" so
        # ConditionFirstBoot holds, then commit the generated ID to the
        # persistent volume instead of /etc.
        #
        boot.initrd.systemd.tmpfiles.settings.preservation."/sysroot${facts.statePath}/etc/machine-id".f = {
          argument = "uninitialized";
        };

        systemd.services.systemd-machine-id-commit = {
          unitConfig.ConditionPathIsMountPoint = [
            ""
            "${facts.statePath}/etc/machine-id"
          ];

          serviceConfig.ExecStart = [
            ""
            "systemd-machine-id-setup --commit --root ${facts.statePath}"
          ];
        };

        #
        # Password changes made at runtime are lost with /etc. Users are
        # declarative; this also enables the NixOS assertion that a
        # wheel user or root has a password.
        #
        users.mutableUsers = false;
      };
    };
}
