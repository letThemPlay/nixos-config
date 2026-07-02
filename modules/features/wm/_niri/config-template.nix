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
      gaps inner=12 top=0
      default-column-width { proportion 0.5; }
      focus-ring { width 2; }
      struts {
          top 32
      }
  }

  spawn-at-startup "uwsm" "finalize" "NIRI_SOCKET"

  spawn-at-startup "swaybg" "--output" "*" "-m" "fill" "-i" "${profileThemeImage}" "--color" "#1a1b26"

  binds {
      "Mod+Return" { spawn "alacritty"; }
      "Mod+Q" { close-window; }
      "Mod+D" { spawn "${pkgs.fuzzel}/bin/fuzzel"; }

      "Mod+Escape"       { spawn "${pkgs.mako}/bin/makoctl" "dismiss"; }
      "Mod+Shift+Escape" { spawn "${pkgs.mako}/bin/makoctl" "dismiss" "-a"; }

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

      "Mod+V"     { consume-window-into-column; }
      "Mod+H"     { expel-window-from-column; }
      "Mod+C"     { center-column; }
      "Mod+Space" { switch-preset-column-width; }

      "Mod+Minus" { set-column-width "-10%"; }
      "Mod+Equal" { set-column-width "+10%"; }
      
      "XF86AudioRaiseVolume" allow-inhibiting=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
      "XF86AudioLowerVolume" allow-inhibiting=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
      "XF86AudioMute"        allow-inhibiting=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-mute"   "@DEFAULT_AUDIO_SINK@" "toggle"; }

      "XF86AudioPlay"        allow-inhibiting=true { spawn "${pkgs.playerctl}/bin/playerctl" "play-pause"; }
      "XF86AudioNext"        allow-inhibiting=true { spawn "${pkgs.playerctl}/bin/playerctl" "next"; }
      "XF86AudioPrev"        allow-inhibiting=true { spawn "${pkgs.playerctl}/bin/playerctl" "previous"; }

      "Mod+Shift+E" { quit; }
  }
''
