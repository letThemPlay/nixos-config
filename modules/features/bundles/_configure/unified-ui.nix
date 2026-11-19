_: {
  ltp = {
    desktop = {
      # The login looks like the lock screen, from the same QML.
      greeter = "quickshell";

      components = {
        bar = "quickshell";
        launcher = "quickshell";
        notifier = "quickshell";
        locker = "quickshell";
        power = "quickshell";
        polkit = "quickshell";
        osd = "quickshell";
        quicksettings = "quickshell";
        calendar = "quickshell";
        wifi = "quickshell";
        bluetooth = "quickshell";
        island = "quickshell";
        batteryAlerts = "quickshell";
        displays = "kanshi";
        automount = "udiskie";
        recorder = "wf-recorder";
        nightLight = "wlsunset";
        tunnels = "quickshell";
        clipboard = "quickshell";
        dock = "quickshell";
      };
    };

    #
    # The shell draws its own launcher, so nothing starts this role.
    # Seshat themes itself from stylix through its own module, so it
    # matches the shell; yazi stays for the terminal.
    #
    apps = {
      roles = {
        launcher = null;
        fileManager = "seshat";
      };
      install = [ "yazi" ];
    };
  };
}
