#
# Which app plays each role when a host chooses nothing.
#
_: {
  terminal = "alacritty";
  editor = "nixvim";
  browser = "firefox";
  fileManager = "yazi";
  launcher = "fuzzel";

  # Hosts that want files to open in something opt in.
  imageViewer = null;
  pdfViewer = null;
  mediaPlayer = null;
}
