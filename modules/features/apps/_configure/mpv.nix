#
# mpv, applied when it plays a role (the media player).
#
_: {
  home-manager.sharedModules = [
    (_: {
      programs.mpv.enable = true;
    })
  ];
}
