{ inputs, ... }: {

  flake.nixosModules.secrets = _: {
    imports = [
      inputs.agenix.nixosModules.default
    ];

    config = {
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
