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

  // Units being started or stopped, and the ones whose last switch failed
  // (polkit refused, or the unit itself failed).
  property var switching: []
  property var failed: []

  readonly property bool busy: switching.length > 0

  function isUp(tunnel) {
    return up.includes(tunnel.unit);
  }

  function isSwitching(tunnel) {
    return switching.includes(tunnel.unit);
  }

  function hasFailed(tunnel) {
    return failed.includes(tunnel.unit);
  }

  function clearFailure() {
    failed = [];
  }

  function refresh() {
    if (available) status.running = true;
  }

  function toggle(tunnel) {
    run(isUp(tunnel) ? "tunnelStop" : "tunnelStart", [tunnel.unit]);
  }

  function stopAll() {
    run("tunnelStop", active.map(tunnel => tunnel.unit));
  }

  // One switch at a time: systemd orders conflicting units, but the shell
  // can only say what it asked for last.
  function run(command, units) {
    const argv = Settings.commands[command];
    if (!argv || busy || units.length === 0) return;

    failed = failed.filter(unit => !units.includes(unit));
    switching = units;
    switcher.command = argv.concat(units);
    switcher.running = true;
  }

  Process {
    id: switcher

    onExited: code => {
      if (code !== 0) root.failed = root.failed.concat(root.switching);
      root.switching = [];
      root.refresh();
    }
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

  Timer {
    interval: 10000
    running: root.available
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
