_: {
  ltp = {
    apps.install = [ "discord" ];
    network.wireless.ui = true;
    hardware = {
      audio.enable = true;
      bluetooth.enable = true;
      backlight.enable = true;
    };
  };
}
