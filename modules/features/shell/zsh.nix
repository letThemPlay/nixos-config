_: {
  flake.nixosModules.zsh = _: {
    config = {
      programs.zsh.enable = true;

      home-manager.sharedModules = [
        ({ osConfig, pkgs, ... }: {
          programs.zsh = {
            enable = true;
            enableCompletion = true;
            autosuggestion.enable = true;
            syntaxHighlighting.enable = true;

            history = {
              size = 10000;
              path = "$HOME/.zsh_history";
            };

            shellAliases = {
              ll = "ls -l";
              la = "ls -la";
              g = "git";
              v = "nvim";
              ff = "fuzzel";
              nrs = "sudo nixos-rebuild switch --flake .#${osConfig.networking.hostName}";
              nrb = "sudo nixos-rebuild boot --flake .#${osConfig.networking.hostName}";
              nfc = "nix flake check";
            };

            initContent = ''
              source ${pkgs.spaceship-prompt}/share/zsh/themes/spaceship.zsh-theme

              SPACESHIP_CHAR_SYMBOL="➜ "
              SPACESHIP_CHAR_SUFFIX=" "
              SPACESHIP_DIR_TRUNC=2
            '';
          };
        })
      ];
    };
  };
}
