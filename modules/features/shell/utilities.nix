_: {
  flake.nixosModules.shell-utilities = _: {
    ltp.shell.aliases.lt = "eza --tree --level=2";

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
        };
      })
    ];
  };
}
