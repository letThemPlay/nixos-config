#
# Default window-management binds, in the action vocabulary. Components
# add their own binds (launchers, media keys, ...) through
# ltp.desktop.binds; a bind there replaces the default for that key.
#
_:
let
  act = action: { inherit action; };

  role = app: { inherit app; };
in
{
  "Mod+Return" = role "terminal";

  "Mod+Q" = act "close";
  "Mod+Shift+E" = act "quit";

  "Mod+Left" = act "focus-left";
  "Mod+Right" = act "focus-right";
  "Mod+Up" = act "focus-up";
  "Mod+Down" = act "focus-down";

  "Mod+Shift+Left" = act "move-left";
  "Mod+Shift+Right" = act "move-right";
  "Mod+Shift+Up" = act "move-up";
  "Mod+Shift+Down" = act "move-down";

  "Mod+F" = act "maximize";
  "Mod+Shift+F" = act "fullscreen";
  "Mod+C" = act "center";

  "Mod+Shift+V" = act "consume";
  "Mod+Shift+H" = act "expel";
  "Mod+Space" = act "cycle-width";
  "Mod+Minus" = act "shrink";
  "Mod+Equal" = act "grow";
}
