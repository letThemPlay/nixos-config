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
        enable = mkEnableOption "Default BootOption" // {
          default = true;
        };
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

      config = mkIf cfg.enable {

        environment.systemPackages = lib.mkMerge [
          (mkIf cfg.tpmUnlock.enable [ pkgs.tpm2-tss ])
          (mkIf cfg.secureBoot.enable [ pkgs.sbctl ])
        ];

        boot = {
          initrd.systemd.enable = true;

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

          lanzaboote = mkIf cfg.secureBoot.enable {
            enable = true;
            pkiBundle = "/var/lib/sbctl";
            configurationLimit = 5;
          };
        };
      };
    };
}
