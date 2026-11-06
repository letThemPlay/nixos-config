pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// How busy the machine is, from the kernel's own counters. It only reads them while
// something is watching, so nothing polls the rest of the time.
Singleton {
  id: root

  property bool watching: false

  // Fractions, or -1 until there's a reading. CPU needs two, as the kernel only counts
  // time since boot, so its use is the change between them.
  property real cpu: -1
  property real memory: -1

  // The filesystem holding /home, as it's kept everywhere, which an erase-on-boot root
  // isn't. It changes slowly, so it's read less often.
  property real disk: -1
  readonly property bool diskReadable: (Settings.commands.diskUsage ?? []).length > 0

  property real lastTotal: 0
  property real lastIdle: 0

  onWatchingChanged: {
    // A second reading soon after the first, so the card doesn't open on a dash.
    if (watching) {
      followUp.restart();
      return;
    }

    cpu = -1;
    memory = -1;
    disk = -1;
    lastTotal = 0;
    lastIdle = 0;
  }

  // df's header, then the size and what's available, in bytes.
  function readDisk(text) {
    const fields = text.trim().split("\n").pop().trim().split(/\s+/).map(Number);

    if (fields.length === 2 && fields[0] > 0) disk = 1 - fields[1] / fields[0];
  }

  function readCpu(text) {
    const fields = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
    const total = fields.slice(0, 8).reduce((sum, field) => sum + field, 0);
    const idle = fields[3] + fields[4];

    if (lastTotal > 0 && total > lastTotal) cpu = 1 - (idle - lastIdle) / (total - lastTotal);

    lastTotal = total;
    lastIdle = idle;
  }

  function readMemory(text) {
    const value = name => Number(new RegExp(name + ":\\s+(\\d+)").exec(text)?.[1] ?? 0);
    const total = value("MemTotal");

    if (total > 0) memory = 1 - value("MemAvailable") / total;
  }

  Timer {
    interval: 2000
    running: root.watching
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      stat.reload();
      meminfo.reload();
    }
  }

  Timer {
    id: followUp

    interval: 500
    onTriggered: {
      if (root.watching) stat.reload();
    }
  }

  Timer {
    interval: 30000
    running: root.watching && root.diskReadable
    repeat: true
    triggeredOnStart: true
    onTriggered: diskUsage.running = true
  }

  Process {
    id: diskUsage

    command: Settings.commands.diskUsage ?? []

    stdout: StdioCollector {
      onStreamFinished: {
        if (root.watching) root.readDisk(text);
      }
    }
  }

  FileView {
    id: stat

    path: "/proc/stat"
    onLoaded: {
      if (root.watching) root.readCpu(text());
    }
  }

  FileView {
    id: meminfo

    path: "/proc/meminfo"
    onLoaded: {
      if (root.watching) root.readMemory(text());
    }
  }
}
