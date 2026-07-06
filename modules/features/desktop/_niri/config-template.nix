{ profileThemeImage, pkgs }:
''
  input {
      keyboard {
          xkb {
              layout "gb"
          }
      }
      touchpad {
          tap
          dwt
      }
  }

  layout {
      gaps 12
      default-column-width { proportion 0.5; }
      struts {
          top 4
      }

      focus-ring {
          off
      }

      shadow {
          off
      }
  }

  window-rule {
      match is-active=true
      opacity 1.0
  }

  window-rule {
      match is-active=false
      opacity 0.85
  }

  spawn-at-startup "uwsm" "finalize" "NIRI_SOCKET"
  spawn-at-startup "uwsm" "app" "--" "waybar" "-c" "~/.config/waybar/dock.json" "-s" "~/.config/waybar/dock-style.css"

  spawn-at-startup "swaybg" "--output" "*" "-m" "fill" "-i" "${profileThemeImage}" "--color" "#1a1b26"

  binds {
      "Mod+Return" { spawn "alacritty"; }
      "Mod+Q" { close-window; }
      "Mod+D" { spawn "${pkgs.fuzzel}/bin/fuzzel"; }
      "Mod+L" { spawn "loginctl" "lock-session"; }
      "Mod+V" { spawn "sh" "-c" "~/.local/bin/cliphist-picker"; }
      "Ctrl+Shift+S" { spawn "uwsm" "app" "--" "sh" "-c" "grim -g \"$(slurp)\" - | swappy -f -"; }

      "Mod+Shift+C" { spawn "uwsm" "app" "--" "wl-color-picker"; }

      "Mod+Escape"       { spawn "uwsm" "app" "--" "swaync-client" "-d"; }
      "Mod+Shift+Escape" { spawn "uwsm" "app" "--" "swaync-client" "-C"; }

      "Mod+Left"  { focus-column-left; }
      "Mod+Right" { focus-column-right; }
      "Mod+Shift+Left"  { move-column-left; }
      "Mod+Shift+Right" { move-column-right; }

      "Mod+F"       { maximize-column; }
      "Mod+Shift+F" { fullscreen-window; }

      "Mod+Up"    { focus-window-or-workspace-up; }
      "Mod+Down"  { focus-window-or-workspace-down; }
      "Mod+Shift+Up"   { move-window-up; }
      "Mod+Shift+Down" { move-window-down; }

      "Mod+Shift+V"     { consume-window-into-column; }
      "Mod+Shift+H"     { expel-window-from-column; }
      "Mod+C"     { center-column; }
      "Mod+Space" { switch-preset-column-width; }

      "Mod+Minus" { set-column-width "-10%"; }
      "Mod+Equal" { set-column-width "+10%"; }
      
      "XF86AudioRaiseVolume" allow-inhibiting=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
      "XF86AudioLowerVolume" allow-inhibiting=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
      "XF86AudioMute"        allow-inhibiting=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-mute"   "@DEFAULT_AUDIO_SINK@" "toggle"; }

      "XF86AudioPlay"  { spawn "uwsm" "app" "--" "playerctl" "play-pause"; }
      "XF86AudioNext"  { spawn "uwsm" "app" "--" "playerctl" "next"; }
      "XF86AudioPrev"  { spawn "uwsm" "app" "--" "playerctl" "previous"; }
      "XF86AudioStop"  { spawn "uwsm" "app" "--" "playerctl" "stop"; }
      "Mod+Shift+E" { quit; }
  }
''
