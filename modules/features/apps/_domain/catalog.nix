#
# The app catalogue: what each app is and which roles it can fill.
# package is a pkgs attribute path, or null when the app's configure
# module provides the program (nixvim). An app with no roles is only
# installed (ltp.apps.install). aliases are shell aliases added while
# the app is in use.
#
_: {

  alacritty = {
    roles = [ "terminal" ];
    package = "alacritty";
    command = [ "alacritty" ];
    appId = "Alacritty";
    desktopEntry = "Alacritty.desktop";
    execFlag = "-e";
  };

  nixvim = {
    roles = [ "editor" ];
    package = null;
    command = [ "nvim" ];
    appId = "nvim";
    desktopEntry = "nvim.desktop";
    opensInTerminal = true;
  };

  firefox = {
    roles = [ "browser" ];
    package = "firefox";
    command = [ "firefox" ];
    appId = "firefox";
    desktopEntry = "firefox.desktop";
  };

  yazi = {
    roles = [ "fileManager" ];
    package = "yazi";
    command = [ "yazi" ];
    appId = "yazi";
    inTerminal = true;
    desktopEntry = "yazi.desktop";
    opensInTerminal = true;
  };

  thunar = {
    roles = [ "fileManager" ];
    package = null;
    command = [ "thunar" ];
    appId = "thunar";
    desktopEntry = "thunar.desktop";
  };

  imv = {
    roles = [ "imageViewer" ];
    package = null;
    command = [ "imv" ];
    appId = "imv";
    desktopEntry = "imv.desktop";
  };

  zathura = {
    roles = [ "pdfViewer" ];
    package = null;
    command = [ "zathura" ];
    appId = "org.pwmt.zathura";
    desktopEntry = "org.pwmt.zathura.desktop";
  };

  mpv = {
    roles = [ "mediaPlayer" ];
    package = null;
    command = [ "mpv" ];
    appId = "mpv";
    desktopEntry = "mpv.desktop";
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

  # Installed without a role (ltp.apps.install); each configure module
  # provides the program.

  git = {
    roles = [ ];
    package = null;
    aliases = {
      g = "git";
      gs = "git status -sb";
      ga = "git add";
      gaa = "git add --all";
      gc = "git commit -m";
      gca = "git commit --amend";
      gp = "git push";
      gpf = "git push --force-with-lease";
      gl = "git pull";
      gd = "git diff";
      gb = "git branch";
      gco = "git checkout";
      gcb = "git checkout -b";
      gsw = "git switch";
      gsc = "git switch -c";

      glog = "git log --graph --oneline --decorate --all";
    };
  };

  discord = {
    roles = [ ];
    package = null;
  };

  steam = {
    roles = [ ];
    package = null;
  };

  flashgbx = {
    roles = [ ];
    package = null;
  };

  eza = {
    roles = [ ];
    package = null;
    aliases.lt = "eza --tree --level=2";
  };

  zoxide = {
    roles = [ ];
    package = null;
  };

}
