#
# What the power menu offers, and the launcher finds by name. The commands
# are compositor-neutral: uwsm ends whichever session it manages. icon names
# an entry of the shell's Icons singleton.
#
_: {

  lock = {
    label = "Lock";
    icon = "lock";
    command = [
      "loginctl"
      "lock-session"
    ];
    confirm = false;
  };

  suspend = {
    label = "Suspend";
    icon = "suspend";
    command = [
      "systemctl"
      "suspend"
    ];
    confirm = false;
  };

  logout = {
    label = "Log out";
    icon = "logout";
    command = [
      "uwsm"
      "stop"
    ];
    confirm = true;
  };

  reboot = {
    label = "Restart";
    icon = "reboot";
    command = [
      "systemctl"
      "reboot"
    ];
    confirm = true;
  };

  poweroff = {
    label = "Shut down";
    icon = "poweroff";
    command = [
      "systemctl"
      "poweroff"
    ];
    confirm = true;
  };

}
