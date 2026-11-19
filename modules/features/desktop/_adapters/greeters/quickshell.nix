_:

#
# The unified shell's greeter (_ui/greeter.qml): a Quickshell surface that
# speaks greetd's protocol, inside a niri of its own, so the login looks
# like the lock screen and the session starts on the same compositor.
# greetd starts the chosen session once this niri exits, so start, the
# program niri runs, ends it after the greeter quits.
#
{
  graphical = true;

  # A private bus, as the greeter user has no session bus of its own.
  command =
    {
      pkgs,
      niri,
      niriConfig,
      ...
    }:
    builtins.concatStringsSep " " [
      "${pkgs.dbus}/bin/dbus-run-session"
      "${niri}/bin/niri"
      "--config"
      niriConfig
    ];

  #
  # keyboard is the session keyboard ({ layout; variant; }), so the
  # password is typed in the layout the session will use.
  #
  niriConfig =
    { keyboard, start }:
    let
      quoted = builtins.toJSON;
    in
    ''
      hotkey-overlay {
          skip-at-startup
      }

      input {
          keyboard {
              xkb {
                  layout ${quoted keyboard.layout}${
                    if keyboard.variant != "" then "\n            variant ${quoted keyboard.variant}" else ""
                  }
              }
          }
          touchpad {
              tap
          }
      }

      prefer-no-csd

      spawn-at-startup ${quoted start}
    '';
}
