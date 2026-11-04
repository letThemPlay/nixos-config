#
# Compositor-neutral window actions. Binds name these; each compositor
# adapter maps the ones it supports to a native command, and
# validation reports a bind whose action an enabled compositor lacks.
#
_:
let
  # Workspaces by number; the default binds use 1 to 9.
  numbered = prefix: builtins.genList (index: "${prefix}-${toString (index + 1)}") 9;
in
numbered "focus-workspace"
++ numbered "move-to-workspace"
++ [
  "close"
  "quit"

  "focus-monitor-left"
  "focus-monitor-right"
  "move-to-monitor-left"
  "move-to-monitor-right"

  "focus-workspace-up"
  "focus-workspace-down"
  "move-to-workspace-up"
  "move-to-workspace-down"

  "screenshot-screen"
  "screenshot-window"

  "overview"
  "toggle-floating"
  "focus-floating"
  "show-hotkeys"

  "focus-left"
  "focus-right"
  "focus-up"
  "focus-down"

  "move-left"
  "move-right"
  "move-up"
  "move-down"

  "maximize"
  "fullscreen"
  "center"

  # Column layouts (niri); other compositors may not map them.
  "consume"
  "expel"
  "cycle-width"
  "grow"
  "shrink"
]
