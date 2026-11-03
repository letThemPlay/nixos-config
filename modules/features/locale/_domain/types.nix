{ lib }:
let
  inherit (lib) mkOption types;

  #
  # The two keyboards are configured separately on purpose: the console
  # uses a kbd keymap (TTYs and the initrd, where the LUKS passphrase is
  # typed), the graphical session an XKB layout. Their names differ
  # (kbd "uk", XKB "gb").
  #
  sessionKeyboard = types.submodule {
    options = {

      layout = mkOption {
        type = types.str;
        default = "gb";
        description = "XKB layout of the graphical session.";
      };

      variant = mkOption {
        type = types.str;
        default = "";
        description = "XKB variant; empty for the layout's default.";
      };

    };
  };

  keyboard = types.submodule {
    options = {

      console = mkOption {
        type = types.str;
        default = "uk";
        description = "kbd keymap for the virtual consoles and the initrd.";
      };

      session = mkOption {
        type = sessionKeyboard;
        default = { };
      };

    };
  };

  model = types.submodule {
    options = {

      timeZone = mkOption { type = types.str; };

      language = mkOption { type = types.str; };

      keyboard = mkOption { type = keyboard; };

    };
  };
in
{
  inherit
    sessionKeyboard
    keyboard
    model
    ;
}
