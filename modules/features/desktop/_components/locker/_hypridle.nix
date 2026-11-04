#
# hypridle settings for a locker: it runs lockCommand when logind asks for a
# lock, and follows the idle policy. One listener per step that is set.
#
{
  lib,
  idle,
  lockCommand,
}:
{
  enable = true;
  settings = {
    general = {
      lock_cmd = lockCommand;
      before_sleep_cmd = "loginctl lock-session";
    };

    listener =
      lib.optional (idle.lockAfter != null) {
        timeout = idle.lockAfter;
        on-timeout = "loginctl lock-session";
      }
      ++ lib.optional (idle.suspendAfter != null) {
        timeout = idle.suspendAfter;
        on-timeout = "systemctl suspend";
      };
  };
}
