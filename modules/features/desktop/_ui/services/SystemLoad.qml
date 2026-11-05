pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// How busy the machine is, from the kernel's own counters. It only reads them while
// something is watching, so nothing polls the rest of the time.
Singleton {
  id: root

  property bool watching: false

  // Fractions, or -1 until there's a reading. CPU needs two, as the kernel only counts
  // time since boot, so its use is the change between them.
  property real cpu: -1
  property real memory: -1

  property real lastTotal: 0
  property real lastIdle: 0

  onWatchingChanged: {
    if (watching) return;

    cpu = -1;
    memory = -1;
    lastTotal = 0;
    lastIdle = 0;
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
