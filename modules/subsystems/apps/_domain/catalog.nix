#
# The app catalogue: what each app is and which roles it can fill.
# package is a pkgs attribute path, or null when the app's configure
# module provides the program (nixvim).
#
_: {

  alacritty = {
    roles = [ "terminal" ];
    package = "alacritty";
    command = [ "alacritty" ];
    appId = "Alacritty";
    execFlag = "-e";
  };

  nixvim = {
    roles = [ "editor" ];
    package = null;
    command = [ "nvim" ];
    appId = "nvim";
  };

  firefox = {
    roles = [ "browser" ];
    package = "firefox";
    command = [ "firefox" ];
    appId = "firefox";
  };

  yazi = {
    roles = [ "fileManager" ];
    package = "yazi";
    command = [ "yazi" ];
    appId = "yazi";
    inTerminal = true;
  };

  fuzzel = {
    roles = [ "launcher" ];
    package = "fuzzel";
    command = [ "fuzzel" ];
    appId = "fuzzel";
    dmenu = [
      "fuzzel"
      "--dmenu"
    ];
  };

}
