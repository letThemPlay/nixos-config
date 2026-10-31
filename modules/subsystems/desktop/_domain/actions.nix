#
# Compositor-neutral window actions. Binds name these; each compositor
# adapter maps the ones it supports to a native command, and
# validation reports a bind whose action an enabled compositor lacks.
#
_: [
  "close"
  "quit"

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
