#
# zoxide for every user, taking over cd. home-manager hooks it into each
# user's shell.
#
_: {
  home-manager.sharedModules = [
    (_: {
      programs.zoxide = {
        enable = true;
        options = [ "--cmd cd" ];
      };
    })
  ];
}
