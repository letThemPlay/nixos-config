_:

#
# tuigreet on the text console. It lists the sessions in sessionsDir and
# starts the chosen one's Exec line; it has no session wrapper, so the
# sessions themselves must start through uwsm.
#
{ pkgs, sessionsDir }:

{
  command = builtins.concatStringsSep " " [
    "${pkgs.tuigreet}/bin/tuigreet"
    "--time"
    "--asterisks"
    "--remember"
    "--remember-session"
    "--sessions"
    sessionsDir
  ];
}
