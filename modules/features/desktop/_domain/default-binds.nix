#
# Default window-management binds, in the action vocabulary. Components
# add their own binds (launchers, media keys, ...) through
# ltp.desktop.binds; a bind there replaces the default for that key.
#
_:
let
  act = action: { inherit action; };

  role = app: { inherit app; };

  # One bind per workspace, 1 to 9.
  numbered =
    key: action:
    builtins.listToAttrs (
      builtins.genList (
        index:
        let
          number = toString (index + 1);
        in
        {
          name = "${key}${number}";
          value = act "${action}-${number}";
        }
      ) 9
    );
in
numbered "Mod+" "focus-workspace"
// numbered "Mod+Shift+" "move-to-workspace"
// {
  "Mod+Ctrl+Left" = act "focus-monitor-left";
  "Mod+Ctrl+Right" = act "focus-monitor-right";
  "Mod+Shift+Ctrl+Left" = act "move-to-monitor-left";
  "Mod+Shift+Ctrl+Right" = act "move-to-monitor-right";

  "Mod+Page_Up" = act "focus-workspace-up";
  "Mod+Page_Down" = act "focus-workspace-down";
  "Mod+Shift+Page_Up" = act "move-to-workspace-up";
  "Mod+Shift+Page_Down" = act "move-to-workspace-down";

  "Mod+O" = act "overview";
  "Mod+Shift+Space" = act "toggle-floating";
  "Mod+Tab" = act "focus-floating";
  "Mod+Shift+Slash" = act "show-hotkeys";

  "Mod+Return" = role "terminal";
  "Mod+D" = role "launcher";

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
