{ inputs, ... }: {

  flake.nixosModules.secrets = { config, lib, ... }: {
    imports = [
      inputs.agenix.nixosModules.default
    ];

    options.ltp.security.secrets.enable =
      lib.mkEnableOption "Agenix cryptographic secrets decryption engine"
      // {
        default = true; # Automatically ready for everything unless explicitly toggled false
      };

    config = lib.mkIf config.ltp.security.secrets.enable {
      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };

  perSystem = { pkgs, ... }: {
    devShells.secrets = pkgs.mkShellNoCC {
      buildInputs = [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  };
}
