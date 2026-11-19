#
# Thunar, applied when it plays a role (the file manager). It is a
# GTK 3 app, so stylix's GTK theme colours it per user. The NixOS
# program, rather than a package, brings its D-Bus services and plugins;
# gvfs gives it trash and volumes (udisks2 comes with automounting),
# tumbler thumbnails and xfconf keeps its preferences.
#
{ lib, pkgs, ... }:
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

  #
  # Thunar's defaults (menu bar, typed location, status bar, a crowded
  # toolbar, full-colour sidebar) clash with the shell's minimal look.
  # Only values that differ from Thunar 4.20's defaults are set; xfconf
  # reapplies them on every activation, so changes in its preferences
  # dialog last until the next switch.
  #
  home-manager.sharedModules = [
    {
      xfconf.settings.thunar = {
        last-menubar-visible = false;
        last-statusbar-visible = false;
        last-location-bar = "ThunarLocationButtons";
        misc-symbolic-icons-in-sidepane = true;
        shortcuts-icon-size = "THUNAR_ICON_SIZE_16";

        # Order and visibility, id:shown. The menu button stands in for
        # the hidden menu bar.
        last-toolbar-items = lib.concatStringsSep "," [
          "back:1"
          "forward:1"
          "location-bar:1"
          "search:1"
          "view-switcher:1"
          "menu:1"
          "open-parent:0"
          "open-home:0"
          "new-tab:0"
          "new-window:0"
          "toggle-split-view:0"
          "undo:0"
          "redo:0"
          "zoom-out:0"
          "zoom-in:0"
          "zoom-reset:0"
          "view-as-icons:0"
          "view-as-detailed-list:0"
          "view-as-compact-list:0"
          "reload:0"
        ];
      };
    }
  ];
}
