#
# The unified shell's center island: the clock when idle, growing to show what's
# happening, and expanding into a card when pressed. The bar gives it the clock,
# media and recording, and it takes ordinary notifications and levels too, except
# over a fullscreen window, which hides the bar.
#
{ pkgs, ... }:
let
  instance = import ../../_ui/instance.nix;

  #
  # The bars beside a playing track. PipeWire's own peak monitor only reports overall
  # loudness, which barely moves in heavily mastered music. cava reads the default
  # output's frequencies and scales itself to the track, and the shell only runs it
  # while the bars can be seen. The bar count matches bar/Visualizer.qml.
  #
  visualizerConfig = pkgs.writeText "ltp-visualizer" ''
    [general]
    bars = 7
    framerate = 30
    autosens = 1

    [input]
    method = pipewire
    source = auto

    [output]
    method = raw
    channels = mono
    raw_target = /dev/stdout
    data_format = ascii
    ascii_max_range = 100
    bar_delimiter = 59
    frame_delimiter = 10
  '';
in
{
  ltp.desktop = {
    binds = {
      "Mod+I" = instance.bind pkgs "island" "toggle";
      "Mod+Shift+I" = instance.bind pkgs "island" "focusCurrent";

      # The island shows the microphone's state, so it's worth having the key for it.
      "XF86AudioMicMute" = {
        spawn = [
          "${pkgs.wireplumber}/bin/wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SOURCE@"
          "toggle"
        ];
        requires = [ "audio" ];
      };
    };

    ui.commands.visualizer = [
      "${pkgs.cava}/bin/cava"
      "-p"
      "${visualizerConfig}"
    ];
  };
}
