#
# eza for every user, with git status, icons and directories first.
# home-manager hooks it into each user's shell.
#
_: {
  home-manager.sharedModules = [
    (_: {
      programs.eza = {
        enable = true;
        git = true;
        icons = "auto";
        extraOptions = [
          "--group-directories-first"
          "--header"
        ];
      };
    })
  ];
}
