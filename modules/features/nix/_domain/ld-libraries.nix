#
# Default nix-ld libraries, as pkgs attribute paths. NixOS adds its own
# base set (zlib, zstd, libstdc++, curl, openssl, attr, libssh, bzip2,
# libxml2, acl, libsodium, util-linux, xz, systemd); these extend it
# for prebuilt CLI and desktop programs (Electron apps, editor remote
# servers, game launchers).
#
_: [
  # Runtime
  "glib"
  "icu"
  "libuuid"
  "libffi"
  "libcap"
  "expat"
  "ncurses"
  "nss"
  "nspr"
  "dbus"
  "libusb1"
  "libsecret"
  "libnotify"

  # Graphics
  "libGL"
  "libGLU"
  "vulkan-loader"
  "mesa"
  "libgbm"
  "libdrm"
  "wayland"
  "libxkbcommon"

  # X11
  "libx11"
  "libxext"
  "libxrender"
  "libxi"
  "libxcursor"
  "libxrandr"
  "libxfixes"
  "libxcb"
  "libxcomposite"
  "libxdamage"
  "libxtst"
  "libxscrnsaver"
  "libxshmfence"
  "libxinerama"

  # Toolkits and fonts
  "gtk3"
  "gdk-pixbuf"
  "atk"
  "at-spi2-atk"
  "at-spi2-core"
  "cairo"
  "pango"
  "fontconfig"
  "freetype"
  "cups"

  # Audio
  "alsa-lib"
  "libpulseaudio"

  # Games
  "SDL2"
]
