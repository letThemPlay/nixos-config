pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// Which of the network feature's tunnels are up. Their units do the work, and
// systemd stops whatever a tunnel conflicts with, so this only asks, starts
// and stops, then asks again.
Singleton {
  id: root

  readonly property var tunnels: Settings.tunnels ?? []
  readonly property bool available: tunnels.length > 0 && Run.has("tunnelStatus")

  // Unit names of the tunnels that are up.
  property var up: []

  readonly property var active: tunnels.filter(tunnel => up.includes(tunnel.unit))

  // The tunnel carrying all traffic, if one does.
  readonly property var full: active.find(tunnel => tunnel.routesAll) ?? null

  function isUp(tunnel) {
    return up.includes(tunnel.unit);
  }

  function refresh() {
    if (available) status.running = true;
  }

  function toggle(tunnel) {
    Run.command(isUp(tunnel) ? "tunnelStop" : "tunnelStart", [tunnel.unit]);
    settle.restart();
  }

  Process {
    id: status

    command: (Settings.commands.tunnelStatus ?? []).concat(root.tunnels.map(tunnel => tunnel.unit))

    // is-active prints one state per unit, in order.
    stdout: StdioCollector {
      onStreamFinished: {
        const states = text.trim().split("\n");
        root.up = root.tunnels.filter((tunnel, index) => states[index] === "active").map(tunnel => tunnel.unit);
      }
    }
  }

  // A tunnel takes a moment to come up or go down; ask again once it has.
  Timer {
    id: settle

    interval: 1500
    onTriggered: root.refresh()
  }

  Timer {
    interval: 10000
    running: root.available
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
