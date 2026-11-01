_: {
  #
  # Volume keys (need sound, ltp.hardware.audio) and media player keys.
  #
  flake.nixosModules.media =
    { pkgs, ... }:
    let
      wpctl = args: {
        spawn = [ "${pkgs.wireplumber}/bin/wpctl" ] ++ args;
        requires = [ "audio" ];
      };

      playerctl = command: {
        spawn = [
          "${pkgs.playerctl}/bin/playerctl"
          command
        ];
      };

      sink = "@DEFAULT_AUDIO_SINK@";
    in
    {
      ltp.desktop.binds = {
        "XF86AudioRaiseVolume" = wpctl [
          "set-volume"
          sink
          "5%+"
        ];
        "XF86AudioLowerVolume" = wpctl [
          "set-volume"
          sink
          "5%-"
        ];
        "XF86AudioMute" = wpctl [
          "set-mute"
          sink
          "toggle"
        ];

        "XF86AudioPlay" = playerctl "play-pause";
        "XF86AudioNext" = playerctl "next";
        "XF86AudioPrev" = playerctl "previous";
        "XF86AudioStop" = playerctl "stop";
      };

      home-manager.sharedModules = [
        (_: {
          home.packages = [ pkgs.playerctl ];
        })
      ];
    };
}
