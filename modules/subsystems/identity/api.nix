{ config, ... }:
let
  identity = config.flake.subsystems.identity;
in
{
  #
  # Options only. Selecting and deriving users is a domain rule and
  # happens in normalize.
  #
  flake.nixosModules.identity-api =
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
            Whether the identity subsystem manages user accounts.
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

        knownFeatures = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          internal = true;

          description = ''
            Every feature registry name, set by the host factory. User
            features are checked against it; null skips the check.
          '';
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
