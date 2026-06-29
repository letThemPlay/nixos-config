# modules/features/secrets.nix
{ inputs, ... }: {

  # 1. Register the agenix NixOS engine globally across your system flake
  flake.nixosModules.secrets = { ... }: {
    imports = [
      inputs.agenix.nixosModules.default
    ];

    # Tell agenix to look for the host's existing SSH host keys on boot to decrypt things
    age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  # 2. Inject the 'agenix' CLI tool into your development terminal environment
  perSystem = { pkgs, ... }: {
    devShells.secrets = pkgs.mkShellNoCC {
      buildInputs = [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  };
}
