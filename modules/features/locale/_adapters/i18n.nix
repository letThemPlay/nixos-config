_:

#
# The locale as plain data in NixOS option shape; the locale module
# applies it.
#
{ model }:

{
  time.timeZone = model.timeZone;

  i18n.defaultLocale = model.language;

  # kbd keymap; with the systemd initrd it is also loaded in stage 1.
  console.keyMap = model.keyboard.console;

  # The system XKB default, for anything without its own layout.
  xkb = {
    inherit (model.keyboard.session) layout variant;
  };
}
