_: {

  package = "zsh";

  # A login shell needs zsh enabled system-wide (completion, /etc/zshrc).
  system.programs = [ "zsh" ];

  render =
    { aliases, pkgs }:
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        history = {
          size = 10000;
          path = "$HOME/.zsh_history";
        };

        shellAliases = aliases;

        initContent = ''
          source ${pkgs.spaceship-prompt}/share/zsh/themes/spaceship.zsh-theme

          SPACESHIP_CHAR_SYMBOL="➜ "
          SPACESHIP_CHAR_SUFFIX=" "
          SPACESHIP_DIR_TRUNC=2
        '';
      };
    };

}
