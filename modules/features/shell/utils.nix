_: {
  flake.nixosModules.shell-utilities = _: {
    home-manager.sharedModules = [
      (_: {
        programs = {
          zoxide = {
            enable = true;
            enableZshIntegration = true;
            options = [
              "--cmd cd"
            ];
          };

          eza = {
            enable = true;
            enableZshIntegration = true;
            git = true;
            icons = "auto";
            extraOptions = [
              "--group-directories-first"
              "--header"
            ];
          };

          zsh.shellAliases = {
            l = "eza -lh --git";
            la = "eza -lah --git";
            lt = "eza --tree --level=2";
          };
        };
      })
    ];
  };
}
