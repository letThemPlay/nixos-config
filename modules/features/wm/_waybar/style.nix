''
  /* Define an alpha-blended custom color token safely */
  @define-color transparent-base alpha(@base00, 0.85);

  * {
      border: none;
      border-radius: 0;
      min-height: 0;
      margin: 3px 3px 3px 3px;
      padding: 0;
  }

  /* Global bar background - Base16 Dark Neutral */
  window#waybar {
    background: transparent;
    #background-color: @transparent-base;
    border-bottom: 2px solid @base01;
    color: @base05;
    transition-property: background-color;
    transition-duration: .5s;

    font-family: "JetBrains Mono", "Symbols Nerd Font Mono", sans-serif;
  }


  /* Universal module configuration container spacing padding */
  #workspaces,
  #window,
  #mpris,
  #clock,
  #battery,
  #cpu,
  #memory,
  #network,
  #wireplumber
  #tray {
      padding: 0 12px;
      margin: 4px 2px;
      border-radius: 6px;
      background-color: @base01;
  }

  #mpris {
    color: @base0D;
  }
  #mpris.paused {
      color: @base04;
  }

  #workspaces button {
      padding: 0 6px;
      color: @base04;
      background: transparent;
      border-bottom: 2px solid transparent;
  }

  /* Niri workspace selector styling */
  #workspaces button.focused {
      color: @base07;
      background-color: @base02;
      border-bottom: 2px solid @base0D;
  }

  #workspaces button.urgent {
      color: @base08;
      background-color: alpha(@base08, 0.2);
  }

  /* Warning state highlighting triggers - Base16 Amber/Orange */
  #battery.warning {
      color: @base09;
  }

  /* Critical state highlighting triggers - Base16 Red */
  #battery.critical:not(.charging) {
      color: @base08;
      animation: blink 0.5s linear infinite alternate;
  }

  /* Standard blinking frames container mapping rules */
  @keyframes blink {
      to {
          background-color: @base08;
          color: @base00;
      }
  }
''
