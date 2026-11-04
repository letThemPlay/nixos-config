pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// Whether the night light schedule is running. It runs as its own unit, so this
// only asks and tells.
Singleton {
  id: root

  readonly property bool available: Run.has("nightLightStatus")

  property bool active: false

  function refresh() {
    if (status.command.length > 0) status.running = true;
  }

  function toggle() {
    Run.command(active ? "nightLightOff" : "nightLightOn");
    active = !active;
  }

  Process {
    id: status

    command: Settings.commands.nightLightStatus ?? []

    stdout: StdioCollector {
      onStreamFinished: root.active = text.trim() === "active"
    }
  }
}
