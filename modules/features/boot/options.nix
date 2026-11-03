_: {
  #
  # Options only. Choosing the loader is a domain rule and happens in
  # normalize.
  #
  flake.nixosModules.boot-options =
    { lib, ... }:
    let
      inherit (lib)
        mkEnableOption
        mkOption
        types
        ;
    in
    {
      options.ltp.boot = {

        enable = mkOption {
          type = types.bool;
          default = true;

          description = ''
            Whether the boot feature configures the boot loader.
          '';
        };

        loader = mkOption {
          type = types.nullOr types.str;
          default = null;

          description = ''
            Boot loader. When null, lanzaboote is used with Secure Boot
            and systemd-boot otherwise.
          '';
        };

        generations = mkOption {
          type = types.ints.positive;
          default = 5;

          description = ''
            Generations kept in the boot menu, for whichever loader is
            selected.
          '';
        };

        secureBoot = {

          enable = mkEnableOption "Secure Boot";

          pkiBundle = mkOption {
            type = types.str;
            default = "/var/lib/sbctl";

            description = ''
              Directory holding the Secure Boot keys (create with
              `sbctl create-keys`). Preserved when storage is enabled.
            '';
          };

        };

        tpmUnlock = {

          enable = mkEnableOption ''
            unlocking the root LUKS volume with the TPM2. Requires
            ltp.storage.encryption. Enroll the key once with
            `systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 <partition>`
          '';

        };

      };
    };
}
