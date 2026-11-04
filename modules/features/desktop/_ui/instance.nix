#
# How the rest of the desktop reaches the running shell: it lives in
# ~/.config/quickshell/<name>, and binds poke it over its IPC socket. A poke
# runs directly: it must feel instant and exits straight away.
#
{
  name = "ltp";

  bind = pkgs: target: method: {
    spawn = [
      "${pkgs.quickshell}/bin/qs"
      "-c"
      "ltp"
      "ipc"
      "call"
      target
      method
    ];
    direct = true;
  };
}
