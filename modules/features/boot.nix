{ inputs, ... }: {
  flake.nixosModules.boot =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.ltp.boot;

      inherit (lib)
        mkIf
        mkEnableOption
        mkForce
        ;
    in
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      options.ltp.boot = {
        secureBoot = {
          enable = mkEnableOption "Secure Boot with Lanzaboote" // {
            default = false;
          };
        };
        tpmUnlock = {
          enable = mkEnableOption "TPM2 automated unlock" // {
            default = false;
          };
        };
      };

      config = {

        environment.systemPackages = lib.mkMerge [
          (mkIf cfg.tpmUnlock.enable [ pkgs.tpm2-tss ])
          (mkIf cfg.secureBoot.enable [ pkgs.sbctl ])
        ];

        # 1. Open a single unified boot property scope
        boot = {
          # Common initrd configuration
          initrd.systemd.enable = true;

          # 2. Safely merge the conditional attribute definitions inline
          loader =
            if cfg.secureBoot.enable then
              {
                systemd-boot.enable = mkForce false;
              }
            else
              {
                systemd-boot = {
                  enable = true;
                  configurationLimit = 5;
                };
                efi.canTouchEfiVariables = true;
              };

          # 3. Apply Lanzaboote configs explicitly when secure boot is toggled
          lanzaboote = mkIf cfg.secureBoot.enable {
            enable = true;
            pkiBundle = "/var/lib/sbctl";
            configurationLimit = 5;
          };
        };
      };
    };
}
