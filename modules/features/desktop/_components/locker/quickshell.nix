#
# The unified shell's lock screen (ext-session-lock), with hypridle for the
# idle policy. It runs as its own short-lived instance: a restart of the bar
# or a home-manager switch must never end a lock.
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ltp.desktop) idle;

  instance = import ../../_ui/instance.nix;

  #
  # A locked compositor stays locked when its lock client dies, and only a new
  # client can unlock it, so a crash starts another. The instance exits 0 once
  # unlocked; --no-duplicate makes a second lock request while locked a no-op.
  #
  lock = pkgs.writeShellScript "ltp-lock" ''
    config="''${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/${instance.name}/lock.qml"

    until ${pkgs.quickshell}/bin/qs --no-duplicate --path "$config"; do
      sleep 1
    done
  '';
in
{
  security.pam.services.ltp-lock = { };

  ltp.desktop.binds."Mod+L".spawn = [
    "loginctl"
    "lock-session"
  ];

  home-manager.sharedModules = [
    (_: {
      services.hypridle = import ./_hypridle.nix {
        inherit lib idle;
        lockCommand = "uwsm app -- ${lock}";
      };
    })
  ];
}
