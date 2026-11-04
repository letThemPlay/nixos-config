#
# Removable drives mount when plugged in. Notifications go to whichever notifier
# the session runs, the tray icon appears only while a drive is mounted and its
# menu unmounts it, and polkit asks through the session's agent when it must.
#
_: {
  services.udisks2.enable = true;

  home-manager.sharedModules = [
    (_: {
      # The shell's tray only speaks status notifier items.
      xsession.preferStatusNotifierItems = true;

      services.udiskie = {
        enable = true;
        automount = true;
        notify = true;
        tray = "auto";
      };
    })
  ];
}
