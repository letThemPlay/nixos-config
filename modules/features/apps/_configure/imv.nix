#
# imv, applied when it plays a role (the image viewer).
#
_: {
  home-manager.sharedModules = [
    (_: {
      programs.imv.enable = true;
    })
  ];
}
