_: {
  layer = "top";
  position = "top";
  margin = "5 7 -5 7";
  modules-left = [
    "clock"
    "hyprland/workspaces"
  ];

  modules-center = [ ];
  modules-right = [
    "tray"
    "network"
    "bluetooth"
    "memory"
    "cpu"
    "wireplumber"
    "battery"
  ];

  battery = {
    states = {
      warning = 30;
      critical = 15;
    };
    format = "{icon}   {capacity}%";
    format-alt = "{icon}   {time}";
    format-icons = [
      ""
      ""
      ""
      ""
      ""
    ];
  };

  clock = {
    interval = 1;
    format = "{:%H:%M %d %b}";
    tooltip = false;
  };

  "custom/weather" = {
    exec = "sleep 5s; curl wttr.in/?format='%t+(%f)'";
    interval = 600;
    tooltip = false;
  };

  tray = {
    icon-space = 18;
    spacing = 10;
  };

  network = {
    interval = 1;
    format-wifi = "    {bandwidthDownBits} on {ipaddr} ( {signalStrength}%    )";
    format-ethernet = "    {bandwidthDownBits} on {ipaddr} ( 󰈀  )";
    format-disconnected = "Disconnected";
    tooltip = false;
    on-click = "nm-connection-editor";
  };

  bluetooth = {
    interval = 1;
    format = "  {status}";
    format-connected = "  {device_alias}";
    format-connected-battery = "  {device_alias} {device_battery_percentage}%";
    format-no-controller = "";
    tooltip-format = "controller = {controller_alias}\t{controller_address}\n\n{num_connections} devices connected";
    tooltip-format-connected = "controller = {controller_alias}\t{controller_address}\n\n{num_connections} devices connected\n\n{device_enumerate}";
    tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
    tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
    on-click = "bluetoothctl power on";
    on-click-right = "bluetoothctl power off";
    on-scroll-up = "bluetoothctl discoverable on";
    on-scroll-down = "bluetoothctl discoverable off";
  };

  memory = {
    interval = 5;
    format = "  {used}GiB";
    states = {
      warning = 70;
      critical = 90;
    };

    tooltip = false;
  };

  cpu = {
    interval = 2;
    format = "  {usage}%";
    states = {
      warning = 70;
      critical = 90;
    };
  };

  wireplumber = {
    format = "󰕾 {volume}%";
    format-muted = "󰖁";
  };
}
