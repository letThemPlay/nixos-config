pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// Whether the screen is warm now: warmed on demand, or the schedule running inside
// its hours. Its units do the work, so this only asks and tells.
Singleton {
  id: root

  readonly property bool available: Run.has("nightLightStatus")

  property bool active: false

  function minutesOf(time) {
    const [hours, minutes] = time.split(":").map(Number);
    return hours * 60 + minutes;
  }

  // The hours usually run through midnight, but needn't.
  function withinHours() {
    const date = new Date();
    const now = date.getHours() * 60 + date.getMinutes();
    const from = minutesOf(Settings.nightLight.from);
    const until = minutesOf(Settings.nightLight.until);

    return from < until ? now >= from && now < until : now >= from || now < until;
  }

  function refresh() {
    if (status.command.length > 0) status.running = true;
  }

  // Turned off within its hours, the schedule would only warm the screen again, so
  // it stops too. Any other time it goes back to waiting for them.
  function toggle() {
    if (!active) Run.command("nightLightWarm");
    else if (withinHours()) Run.command("nightLightOff");
    else Run.command("nightLightSchedule");

    active = !active;
  }

  Process {
    id: status

    command: Settings.commands.nightLightStatus ?? []

    stdout: StdioCollector {
      onStreamFinished: {
        const [warm, schedule] = text.trim().split("\n");
        root.active = warm === "active" || (schedule === "active" && root.withinHours());
      }
    }
  }
}
