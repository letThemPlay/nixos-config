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
    in
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      options.ltp.boot = {
        enable = lib.mkEnableOption "Default BootOption" |> (opt: opt // { default = true; });

        secureBoot.enable =
          lib.mkEnableOption "Secure Boot with Lanzaboote" |> (opt: opt // { default = false; });

        tpmUnlock.enable = lib.mkEnableOption "TPM2 automated unlock" |> (opt: opt // { default = false; });
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages =
          lib.optionals cfg.tpmUnlock.enable [ pkgs.tpm2-tss ]
          ++ lib.optionals cfg.secureBoot.enable [ pkgs.sbctl ];

        boot = {
          initrd.systemd.enable = true;

          loader = {
            systemd-boot = {
              enable = if cfg.secureBoot.enable then lib.mkForce false else true;
              configurationLimit = 5;
            };
            efi.canTouchEfiVariables = !cfg.secureBoot.enable;
          };

          lanzaboote = lib.mkIf cfg.secureBoot.enable {
            enable = true;
            pkiBundle = "/var/lib/sbctl";
            configurationLimit = 5;
          };
        };
      };
    };
}
