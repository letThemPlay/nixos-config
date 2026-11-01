#
# Discord for every user, through home-manager.
#
{ pkgs, ... }:
{
  home-manager.sharedModules = [
    (_: {
      programs.discord = {
        enable = true;
        package = pkgs.discord;
      };
    })
  ];
}
