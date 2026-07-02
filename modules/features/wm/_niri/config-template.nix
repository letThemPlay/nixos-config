{ config }:
''
  // modules/features/wm/_niri/config.kdl (Compiled dynamic output)

  debug {
      renderer "pixman"
  }

  input {
      touchpad {
          tap
          dwt
      }
  }

  layout {
      gaps 12
      default-column-width { proportion 0.5; }
      focus-ring { width 2; }
      struts {
          top 32
      }
  }

  spawn-at-startup "swaybg" "-m" "fill" "-i" "${toString config.stylix.image}"

  binds {
      "Mod+Return" { spawn "alacritty"; }
      "Mod+Q" { close-window; }
      
      "Mod+Left"  { focus-column-left; }
      "Mod+Right" { focus-column-right; }
      
      "Mod+Shift+E" { quit; }
  }
''
