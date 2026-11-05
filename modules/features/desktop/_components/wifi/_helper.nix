#
# The shell's way to iwd, as a program of its own so a VM test can run it against
# a real iwd without the shell. The string annotations are D-Bus signatures, which
# flake8 reads as undefined names.
#
pkgs:
pkgs.writers.writePython3 "ltp-wifi" {
  libraries = [ pkgs.python3Packages.dbus-fast ];
  flakeIgnore = [
    "E501"
    "F821"
  ];
} (builtins.readFile ./_iwd.py)
