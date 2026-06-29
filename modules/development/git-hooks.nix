{ inputs, ... }: {

  imports = [
    inputs.git-hooks-nix.flakeModule
  ];

  perSystem = { config, pkgs, ... }: {

    pre-commit.settings = {
      hooks = {
        nixfmt.enable = true;
        statix.enable = true;
        deadnix.enable = true;
      };
    };

    devShells.default = pkgs.mkShell {
      name = "nix-config-devshell";
      buildInputs = config.pre-commit.settings.enabledPackages ++ [ pkgs.git ];

      inherit (config.pre-commit.devShell) shellHook;
    };
  };
}
