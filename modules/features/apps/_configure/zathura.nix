#
# zathura, applied when it plays a role (the PDF viewer).
#
_: {
  home-manager.sharedModules = [
    (_: {
      programs.zathura.enable = true;
    })
  ];
}
