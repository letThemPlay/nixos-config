{ profileThemeImage, pkgs }:
''
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

  spawn-at-startup "swaybg" "--output" "*" "-m" "fill" "-i" "${profileThemeImage}" "--color" "#1a1b26"

  binds {
      "Mod+Return" { spawn "alacritty"; }
      "Mod+Q" { close-window; }
      
      "Mod+Left"  { focus-column-left; }
      "Mod+Right" { focus-column-right; }
      
      "XF86AudioRaiseVolume" allow-inhibiting=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
      "XF86AudioLowerVolume" allow-inhibiting=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
      "XF86AudioMute"        allow-inhibiting=true { spawn "${pkgs.wireplumber}/bin/wpctl" "set-mute"   "@DEFAULT_AUDIO_SINK@" "toggle"; }

      "XF86AudioPlay"        allow-inhibiting=true { spawn "${pkgs.playerctl}/bin/playerctl" "play-pause"; }
      "XF86AudioNext"        allow-inhibiting=true { spawn "${pkgs.playerctl}/bin/playerctl" "next"; }
      "XF86AudioPrev"        allow-inhibiting=true { spawn "${pkgs.playerctl}/bin/playerctl" "previous"; }

      "Mod+Shift+E" { quit; }
  }
''
