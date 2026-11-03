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

        # Coding standard: no `rec`; use let … in { inherit …; }.
        no-rec = {
          enable = true;
          name = "no-rec";
          entry = toString (
            pkgs.writeShellScript "no-rec" ''
              if ${pkgs.gnugrep}/bin/grep -nE '(^|[^[:alnum:]_-])rec[[:space:]]*\{' "$@"; then
                echo "rec is not allowed: use let … in { inherit …; } (or lib.fix for a core)." >&2
                exit 1
              fi
            ''
          );
          files = "\\.nix$";
          language = "system";
          pass_filenames = true;
        };
      };
    };

    devShells.default = pkgs.mkShell {
      name = "nix-config-devshell";
      buildInputs = config.pre-commit.settings.enabledPackages ++ [ pkgs.git ];

      inherit (config.pre-commit.devShell) shellHook;
    };
  };
}
