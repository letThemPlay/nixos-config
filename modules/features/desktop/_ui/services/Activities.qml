pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// What's going on in the background: copies and downloads, which the transfers command
// watches for, and the shell's own timers. Timers keep their end time rather than
// counting down, so they stay accurate across a suspend or a reload of the shell.
Singleton {
  id: root

  property var transfers: []
  property string lastReport: ""

  // Timers need this to tick, so only they run it.
  property real now: Date.now()

  readonly property var timers: JSON.parse(kept.timers)

  // Transfers first, as they're the ones that come and go.
  readonly property var items: transfers.map(describeTransfer).concat(
    [...timers].sort((a, b) => a.ends - b.ends).map(describeTimer)
  )

  // Rows are built from these, so a row isn't rebuilt each time its numbers change.
  readonly property var keys: items.map(item => item.key)
  readonly property bool active: items.length > 0
  readonly property var primary: items[0] ?? null

  function item(key) {
    return items.find(candidate => candidate.key === key) ?? null;
  }

  function size(bytes) {
    const units = ["B", "KiB", "MiB", "GiB", "TiB"];
    let value = bytes;
    let unit = 0;

    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit += 1;
    }

    return (unit > 1 ? value.toFixed(1) : Math.round(value)) + " " + units[unit];
  }

  function clock(seconds) {
    const whole = Math.max(0, Math.ceil(seconds));
    const hours = Math.floor(whole / 3600);
    const minutes = Math.floor(whole / 60) % 60;
    const rest = whole % 60;
    const padded = number => (number < 10 ? "0" : "") + number;

    return hours > 0 ? hours + ":" + padded(minutes) + ":" + padded(rest) : minutes + ":" + padded(rest);
  }

  // A fraction of -1 is one with no total to measure against. Brief is for the island's
  // pill, and detail for the card.
  function describeTransfer(transfer) {
    const speed = size(transfer.rate) + "/s";

    if (transfer.total > 0) {
      const fraction = transfer.done / transfer.total;
      const left = transfer.remaining >= 0 ? clock(transfer.remaining) + " left" : speed;

      return {
        key: transfer.kind + ":" + transfer.id,
        icon: transfer.kind === "download" ? "download" : "fileCopy",
        name: transfer.name,
        fraction: fraction,
        brief: Math.round(fraction * 100) + "%",
        detail: size(transfer.done) + " of " + size(transfer.total) + " · " + left
      };
    }

    return {
      key: transfer.kind + ":" + transfer.id,
      icon: transfer.kind === "download" ? "download" : "fileCopy",
      name: transfer.name,
      fraction: -1,
      brief: size(transfer.done),
      detail: size(transfer.done) + " · " + speed
    };
  }

  function describeTimer(timer) {
    const left = (timer.ends - now) / 1000;

    return {
      key: "timer:" + timer.id,
      icon: "timer",
      name: timer.label,
      fraction: Math.min(1, Math.max(0, 1 - left / timer.seconds)),
      brief: clock(left),
      detail: clock(left) + " left",
      timerId: timer.id
    };
  }

  function startTimer(minutes) {
    if (minutes <= 0) return;

    const seconds = minutes * 60;
    const started = Date.now();

    now = started;
    kept.timers = JSON.stringify(timers.concat([{
      id: started,
      label: minutes + " min timer",
      seconds: seconds,
      ends: started + seconds * 1000
    }]));
  }

  function cancelTimer(id) {
    kept.timers = JSON.stringify(timers.filter(timer => timer.id !== id));
  }

  // A timer that ended while the shell was away still gets to say so.
  function checkTimers() {
    now = Date.now();

    for (const timer of timers.filter(candidate => candidate.ends <= now)) {
      Run.command("timerDone", [timer.label + " finished"]);
      cancelTimer(timer.id);
    }
  }

  // As text, as a reload starts a new engine, which can't take the old one's arrays.
  PersistentProperties {
    id: kept

    reloadableId: "activityTimers"

    property string timers: "[]"
  }

  Timer {
    interval: 1000
    running: root.timers.length > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkTimers()
  }

  Process {
    command: Settings.commands.transfers ?? []
    running: command.length > 0

    stdout: SplitParser {
      onRead: line => {
        if (line === root.lastReport) return;

        root.lastReport = line;
        root.transfers = JSON.parse(line);
      }
    }
  }

  IpcHandler {
    target: "timer"

    function start(minutes: int): void {
      root.startTimer(minutes);
    }

    function cancel(): void {
      kept.timers = "[]";
    }
  }
}
