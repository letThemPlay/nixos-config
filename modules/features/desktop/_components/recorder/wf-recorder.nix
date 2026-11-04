#
# Screen recording, driven by the unified shell. Recordings run as a transient
# user unit, so restarting the shell can't lose one, and SIGINT lets wf-recorder
# finish the file when it stops.
#
{
  config,
  desktop,
  pkgs,
  ...
}:
let
  instance = import ../../_ui/instance.nix;

  unit = "ltp-recording";

  # Every enabled compositor is offered at login, but one names the outputs here.
  compositor = desktop.compositors.${builtins.head config.ltp.desktop.compositors};

  finished = pkgs.writeShellApplication {
    name = "ltp-recording-finished";
    runtimeInputs = [ pkgs.libnotify ];
    text = ''
      if [ -s "$1" ]; then
        notify-send --app-name=Recorder --icon=video-x-generic "Recording saved" "$1"
      else
        notify-send --app-name=Recorder --icon=dialog-error "Recording failed" "Nothing was saved."
      fi
    '';
  };

  # Takes what to record, screen or region, and whether to take system audio.
  # Stops a recording in progress instead, as does asking for stop.
  toggle = pkgs.writeShellApplication {
    name = "ltp-recording-toggle";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.slurp
      pkgs.systemd
      pkgs.${compositor.system.package}
    ];
    text = ''
      if systemctl --user --quiet is-active ${unit}.service; then
        systemctl --user stop ${unit}.service
        exit 0
      fi

      # Asked to stop what already ended: never start one by accident.
      if [ "$1" = stop ]; then
        exit 0
      fi

      directory="$HOME/Videos/Recordings"
      mkdir -p "$directory"
      file="$directory/Recording_$(date +%Y%m%d_%H%M%S).mp4"

      arguments=(-f "$file" -x yuv420p -y)

      if [ "$1" = region ]; then
        # Cancelling the selection cancels the recording.
        geometry=$(slurp) || exit 0
        arguments+=(-g "$geometry")
      else
        output=$(${toString compositor.focusedOutput.command} | jq -r '${compositor.focusedOutput.filter}')
        arguments+=(-o "$output")
      fi

      if [ "$2" = audio ]; then
        arguments+=(--audio=@DEFAULT_MONITOR@)
      fi

      systemd-run --user --quiet --collect \
        --unit=${unit} \
        --property=KillSignal=SIGINT \
        --property=TimeoutStopSec=15 \
        --property="ExecStopPost=${finished}/bin/ltp-recording-finished $file" \
        --setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
        ${pkgs.wf-recorder}/bin/wf-recorder "''${arguments[@]}"
    '';
  };
in
{
  ltp.desktop = {
    binds = {
      "Mod+Shift+R" = instance.bind pkgs "recorder" "screen";
      "Mod+Ctrl+R" = instance.bind pkgs "recorder" "region";
    };

    ui.commands = {
      recordingToggle = [ "${toggle}/bin/ltp-recording-toggle" ];

      recordingStatus = [
        "${pkgs.systemd}/bin/systemctl"
        "--user"
        "is-active"
        "${unit}.service"
      ];
    };
  };
}
