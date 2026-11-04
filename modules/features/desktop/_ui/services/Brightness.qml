pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// The screen's brightness, as one value every surface reads, so a slider and the
// level display can't disagree. The system sends no signal when it changes, so
// whatever changes it asks for a refresh.
Singleton {
  id: root

  property real level: 0

  // Whether a refresh in progress should be shown, and whether another is due
  // because the level moved again while it ran.
  property bool announcing: false
  property bool again: false

  // After a refresh that asked to be shown: the keys, not a slider.
  signal announced

  function refresh(announce) {
    if (announce) announcing = true;

    if (status.running) again = true;
    else if (status.command.length > 0) status.running = true;
  }

  // A drag reports many levels; each one would be a process and a logind call.
  function set(next) {
    level = next;
    apply.restart();
  }

  Process {
    id: status

    command: Settings.commands.brightnessStatus ?? []

    onRunningChanged: {
      if (!running && root.again) {
        root.again = false;
        running = true;
      }
    }

    stdout: StdioCollector {
      // device,class,current,percent%,max
      onStreamFinished: {
        const percent = parseInt(text.trim().split(",")[3]);
        if (isNaN(percent)) return;

        root.level = percent / 100;

        if (root.announcing && !root.again) {
          root.announcing = false;
          root.announced();
        }
      }
    }
  }

  Timer {
    id: apply

    interval: Theme.motionFast
    onTriggered: Run.command("brightnessSet", [Math.round(root.level * 100) + "%"])
  }
}
