#
# Seshat, applied when it plays a role (the file manager). Its own Home
# Manager module installs it and, with stylix in Home Manager, themes it
# from the system palette and fonts, so nothing here sets colours.
# settings.toml is left to Seshat, which rewrites it whenever a setting
# changes. GVfs gives it the Trash, network mounts and the device list.
#
{ inputs, ... }:
{
  home-manager.sharedModules = [
    inputs.seshat.homeModules.default
    { programs.seshat.enable = true; }
  ];

  services.gvfs.enable = true;
}
