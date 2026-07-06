{ pkgs }:
{
  layer = "top";
  position = "top";
  height = 32;
  spacing = 4;
  margin = "5 7 -5 7";

  fixed-center = true;

  modules-left = [
    "niri/workspaces"
    "niri/window"
    "mpris"
  ];
  modules-center = [ "clock" ];
  modules-right = [
    "network"
    "cpu"
    "memory"
    "wireplumber"
    "battery"
    "tray"
  ];

  "niri/workspaces" = {
    format = "{name}";
    all-outputs = true;
  };

  "niri/window" = {
    format = "{}";
    max-length = 20;
    separate-outputs = true;

    expand = false;
  };

  "mpris" = {
    format = "{player_icon}  {title}";
    format-paused = "{status_icon}  <i>{title}</i>";
    max-length = 35;
    player-icons = {
      default = "🎵";
      firefox = "";
    };
    status-icons = {
      paused = "⏸";
    };
  };

  clock = {
    tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
    format-alt = "{:%Y-%m-%d}";
  };

  cpu = {
    format = "  {usage}%";
    tooltip = false;
  };
  memory = {
    format = "  {}%";
  };

  wireplumber = {
    format = "{icon}  {volume}%";
    format-muted = "    Muted";
    on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    format-icons = [
      "  "
      "  "
      "  "
    ];
    max-volume = 100;
    scroll-step = 5;
  };

  battery = {
    states = {
      warning = 30;
      critical = 15;
    };
    format = "{icon}  {capacity}%";
    format-charging = "  {capacity}%";
    format-plugged = "  {capacity}%";
    format-icons = [
      ""
      ""
      ""
      ""
      ""
    ];
  };

  network = {
    format-wifi = "  {essid}";
    format-ethernet = "${builtins.fromJSON "\"\\uf0200\""}  {ipaddr}/{cidr}";
    format-disconnected = "⚠  Disconnected";
  };
}
