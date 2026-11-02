{ config, ... }:
let
  secrets = config.ltp.features.secrets;
in
{
  # Options only.
  flake.nixosModules.secrets-options =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.secrets = {

        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the secrets feature configures agenix.";
        };

        identityPaths = mkOption {
          type = types.listOf types.str;
          default = [ "/etc/ssh/ssh_host_ed25519_key" ];
          description = ''
            Private keys agenix decrypts with. They are preserved
            across root rollbacks.
          '';
        };

        hostKeyProvisioned = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether the SSH host key used as an identity is provisioned
            by hand. Without it (or services.openssh), nothing creates
            the key and secrets cannot be decrypted.
          '';
        };

        files = mkOption {
          type = types.attrsOf secrets.types.file;
          default = { };

          example = {
            tailscale-authkey = { };
          };

          description = ''
            Secrets this host uses: secrets/<name>.age, encrypted (per
            secrets/secrets.nix) for this host's key in
            secrets/keys.nix.
          '';
        };

        facts.paths = mkOption {
          type = types.attrsOf types.str;
          readOnly = true;
          description = "Runtime path of each declared secret.";
        };

      };
    };
}
