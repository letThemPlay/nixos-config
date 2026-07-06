''
  @define-color transparent-base alpha(@base00, 0.85);

  window#waybar {
    background-color: transparent;
    color: u/fg;
    border-radius: 8px;
  }

  #waybar > box {
    margin: 4px 8px 0 8px;
    padding: 2px;
    background-color: u/bg;
    border-radius: 8px;
  }

  .modules-left,
  .modules-center,
  .modules-right {
      background-color: @transparent-base;
      opacity: 0.75;
      border-radius: 10px;
      color: #CDD6F4;
      font-family: 'Noto sans';
      font-size: 12px;
  }

  #workspaces button {
      border-radius: 8px;
      color: #ebdbb2;
      padding: 0px 3px;
  }

  #clock,
  #custom-weather,
  #cpu,
  #memory,
  #network,
  #wireplumber,
  #tray,
  #battery,
  #bluetooth {
      padding: 0.2rem 0.5rem;
  }

  #cpu.warning {
      color: #d79921;
  }

  #cpu.critical {
      color: #cc241d;
  }

  #memory.warning {
      color: #d79921;
  }

  #memory.critical {
      color: #cc241d;
  }

  #network.disconnected {
      color: #d79921;
  }

  #wireplumber.muted {
      color: #d79921;
  }

  #workspaces button {
      border-radius: 8px;
      color: #ebdbb2;
      padding: 0px 3px;
  }

  #workspaces button.active {
      color: #282828;
      /* background-color: #458588; */
      background-color: #5677FC;
  }

  #workspaces button.persistent,
  #workspaces button.special {
      font-weight: bold;
      font-style: italic;
  }

  #bluetooth.disabled,
  #bluetooth.off {
      color: #d79921
  }

  #bluetooth.connected {
      color: #689d6a
  }

  #bluetooth.discoverable {
      text-decoration: underline;
  }

''
