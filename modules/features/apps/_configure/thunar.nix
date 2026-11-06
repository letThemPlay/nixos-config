#
# Thunar, applied when it plays a role (the file manager). It is a
# GTK 3 app, so stylix's GTK theme colours it per user. The NixOS
# program, rather than a package, brings its D-Bus services and plugins;
# gvfs gives it trash and volumes (udisks2 comes with automounting),
# tumbler thumbnails and xfconf keeps its preferences.
#
{ pkgs, ... }:
{
  programs = {
    thunar = {
      enable = true;

      plugins = [
        pkgs.thunar-volman
        pkgs.thunar-archive-plugin
      ];
    };

    xfconf.enable = true;
  };

  services = {
    gvfs.enable = true;
    tumbler.enable = true;
  };
}
