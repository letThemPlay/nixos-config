pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// The screen recording, which runs as its own unit. The shell only starts it and
// watches it, so it can pick up one already running when it restarts.
Singleton {
  id: root

  readonly property bool available: Run.has("recordingToggle")

  property bool active: false
  property bool withAudio: false
  property int seconds: 0

  // Between asking for a recording and seeing it run, which takes as long as a
  // region takes to select.
  property bool awaiting: false
  property string mode: "screen"

  readonly property string elapsed: {
    const minutes = Math.floor(seconds / 60);
    const rest = seconds % 60;
    return minutes + ":" + (rest < 10 ? "0" : "") + rest;
  }

  function check() {
    if (status.command.length > 0) status.running = true;
  }

  function start(newMode) {
    if (active) {
      stop();
      return;
    }

    // Starts once the panel is out of the way, so it isn't in the first frames
    // and doesn't sit above a region selection.
    Ui.close();
    mode = newMode;
    begin.restart();
  }

  function stop() {
    Run.command("recordingToggle", ["stop", "none"]);
    active = false;
  }

  Timer {
    id: begin

    interval: Theme.motionNormal * 2
    onTriggered: {
      Run.command("recordingToggle", [root.mode, root.withAudio ? "audio" : "none"]);
      root.awaiting = true;
      giveUp.restart();
    }
  }

  // A cancelled region selection never starts anything.
  Timer {
    id: giveUp

    interval: 60000
    onTriggered: root.awaiting = false
  }

  Timer {
    interval: 1000
    running: root.active || root.awaiting
    repeat: true
    onTriggered: {
      root.check();
      if (root.active) root.seconds += 1;
    }
  }

  Process {
    id: status

    command: Settings.commands.recordingStatus ?? []

    stdout: StdioCollector {
      onStreamFinished: {
        const running = text.trim() === "active";

        if (running && !root.active) root.seconds = 0;
        if (running) root.awaiting = false;

        root.active = running;
      }
    }
  }

  IpcHandler {
    target: "recorder"

    function screen(): void {
      root.start("screen");
    }

    function region(): void {
      root.start("region");
    }

    function stop(): void {
      root.stop();
    }
  }
}
