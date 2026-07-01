''
  /* Global bar background - Base16 Dark Neutral */
  window#waybar {
      background-color: rgba(@base00, 0.85);
      border-bottom: 2px solid @base01;
      color: @base05;
      transition-property: background-color;
      transition-duration: .5s;
  }

  /* Universal module configuration container spacing padding */
  #workspaces,
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

  /* Workspaces focus states overrides */
  #workspaces button {
      padding: 0 4px;
      color: @base04;
      background-color: transparent;
  }

  #workspaces button.active {
      color: @base07;
      background-color: @base02;
      border-bottom: 2px solid @base0D;
  }

  #workspaces button.urgent {
      color: @base08;
      background-color: rgba(@base08, 0.2);
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
''
