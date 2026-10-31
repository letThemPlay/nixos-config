#
# Default app roles. Hosts and components override single fields with
# ltp.desktop.apps.<role>; a role that is not here is added with the
# defaults from types.appDefaults.
#
_: {

  terminal = {
    package = "alacritty";
    command = [ "alacritty" ];
    appId = "Alacritty";
    execFlag = "-e";
  };

  browser = {
    package = "firefox";
    command = [ "firefox" ];
    appId = "firefox";
  };

  fileManager = {
    package = "yazi";
    command = [ "yazi" ];
    appId = "yazi";
    inTerminal = true;
  };

}
