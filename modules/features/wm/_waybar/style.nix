''
  /* 👑 THE TRANS_LUCENCY FIX: Define an alpha-blended custom color token safely */
  @define-color transparent-base alpha(@base00, 0.85);

  /* Global bar background - Base16 Dark Neutral */
  window#waybar {
      background-color: @transparent-base; /* 👑 Applied the safe translucent token here */
      border-bottom: 2px solid @base01;
      color: @base05;
      transition-property: background-color;
      transition-duration: .5s;
  }

  /* Universal module configuration container spacing padding */
  #workspaces,
  #window, /* 👑 Added #window here so Niri's active title widget inherits your theme box style */
  #clock,
  #battery,
  #cpu,
  #memory,
  #network,
  #tray {
      padding: 0 12px;
      margin: 4px 2px;
      border-radius: 6px;
      background-color: @base01;
  }

  #workspaces button {
      padding: 0 6px;
      color: @base04;
      background: transparent;
      border-bottom: 2px solid transparent; /* Prevents text layout shifting on focus */
  }

  /* Niri uses .focused instead of Hyprland's .active layout class */
  #workspaces button.focused {
      color: @base07;
      background-color: @base02;
      border-bottom: 2px solid @base0D;
  }

  #workspaces button.urgent {
      color: @base08;
      background-color: alpha(@base08, 0.2); /* 👑 Fixed the nested rgba trap here too */
  }

  /* Warning state highlighting triggers - Base16 Amber/Orange */
  #battery.warning {
      color: @base09;
  }

  /* Critical state highlighting triggers - Base16 Red */
  #battery.critical:not(.charging) {
      color: @base08;
      animation-name: blink;
      animation-duration: 0.5s;
      animation-timing-function: linear;
      animation-iter-count: infinite;
      animation-direction: alternate;
  }

  /* 👑 Added the missing blink animation keyframes so critical alerts actually flash */
  @keyframes blink {
      to {
          background-color: @base08;
          color: @base00;
      }
  }
''
