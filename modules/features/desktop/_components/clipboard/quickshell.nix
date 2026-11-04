#
# Clipboard history on the unified shell's search surface, instead of a
# separate dmenu.
#
{ pkgs, ... }:
let
  instance = import ../../_ui/instance.nix;

  # Takes one line of `cliphist list` and copies that entry back.
  copy = pkgs.writeShellScript "ltp-clipboard-copy" ''
    printf '%s' "$1" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
  '';
in
{
  ltp.desktop = {
    binds."Mod+V" = instance.bind pkgs "launcher" "clipboard";

    ui.commands = {
      clipboardList = [
        "${pkgs.cliphist}/bin/cliphist"
        "list"
      ];

      # A session application: wl-copy stays behind to serve the clipboard, and
      # must outlive a restart of the shell.
      clipboardCopy = [
        "uwsm"
        "app"
        "--"
        "${copy}"
      ];
    };
  };

  home-manager.sharedModules = [
    (_: {
      home.packages = [
        pkgs.cliphist
        pkgs.wl-clipboard
      ];

      services.cliphist = {
        enable = true;
        allowImages = true;
      };
    })
  ];
}
