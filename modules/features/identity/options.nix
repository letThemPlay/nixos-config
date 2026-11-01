{ config, ... }:
let
  identity = config.flake.features.identity;
in
{
  #
  # Options only. Selecting and deriving users is a domain rule and
  # happens in normalize.
  #
  flake.nixosModules.identity-options =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.identity = {

        enable = mkOption {
          type = types.bool;
          default = true;

          description = ''
            Whether the identity feature manages user accounts.
          '';
        };

        users = mkOption {
          type = types.attrsOf identity.types.user;
          default = { };

          description = ''
            User catalogue, one entry per file in modules/users/_users.
            Hosts enable the users they have.
          '';
        };

        passwordDirectory = mkOption {
          type = types.nullOr types.str;
          default = null;

          description = ''
            Directory holding one hashed password file per user, named
            after the user (create with `mkpasswd -m yescrypt`). When
            null, it is <statePath>/secrets/passwords on an ephemeral
            root and unmanaged otherwise.

            It must live on a volume mounted in initrd: userborn creates
            users before agenix decrypts secrets.
          '';
        };

        escalation = mkOption {
          type = types.nullOr types.str;
          default = "sudo-rs";
          description = "How admin users (wheel) get root: a registered tool (sudo, sudo-rs), or null for none.";
        };

        gpg.enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether this host sets up the users' OpenPGP keys: gpg,
            gpg-agent with pinentry, SSH through the agent, smartcard
            rules and git commit signing.
          '';
        };

        knownBundles = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          internal = true;

          description = ''
            Every bundle name, set by the host factory. User bundles are
            checked against it; null skips the check.
          '';
        };

        facts.gpg = mkOption {
          type = types.bool;
          readOnly = true;
          description = "Whether this host renders the users' OpenPGP setup.";
        };

        facts.users = mkOption {
          type = types.attrsOf identity.types.modelUser;
          readOnly = true;

          description = ''
            Users enabled on this host, normalized. Features read users
            from here.
          '';
        };

      };
    };
}
