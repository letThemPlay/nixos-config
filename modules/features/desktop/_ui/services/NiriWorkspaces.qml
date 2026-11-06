pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// Which of niri's workspaces have windows, from its event stream. The workspace protocol
// the bar lists them with doesn't say, and niri keeps an empty one at the end of each
// output, and the focused one even once it's emptied, so the bar can't tell by itself.
Singleton {
  id: root

  readonly property bool available: (Settings.commands.niriEvents ?? []).length > 0

  // Workspace ID -> { output, idx, name }, and window ID -> workspace ID.
  property var workspaces: ({})
  property var windows: ({})

  // By output and position, as the bar lists them; idx counts from 1 on each output.
  // Null where niri hasn't said, so nothing is faded on a guess.
  function at(output, idx) {
    const occupied = Object.values(windows);

    for (const [id, workspace] of Object.entries(workspaces)) {
      if (workspace.output === output && workspace.idx === idx) {
        return { name: workspace.name, occupied: occupied.includes(Number(id)) };
      }
    }
    return null;
  }

  function handle(event) {
    if (event.WorkspacesChanged) {
      const next = {};
      for (const workspace of event.WorkspacesChanged.workspaces) {
        next[workspace.id] = { output: workspace.output, idx: workspace.idx, name: workspace.name ?? "" };
      }
      workspaces = next;
    } else if (event.WindowsChanged) {
      const next = {};
      for (const window of event.WindowsChanged.windows) {
        if (window.workspace_id !== null) next[window.id] = window.workspace_id;
      }
      windows = next;
    } else if (event.WindowOpenedOrChanged) {
      const window = event.WindowOpenedOrChanged.window;
      const next = Object.assign({}, windows);
      if (window.workspace_id !== null) next[window.id] = window.workspace_id;
      else delete next[window.id];
      windows = next;
    } else if (event.WindowClosed) {
      const next = Object.assign({}, windows);
      delete next[event.WindowClosed.id];
      windows = next;
    }
  }

  Process {
    id: stream

    command: Settings.commands.niriEvents ?? []
    running: root.available

    stdout: SplitParser {
      onRead: line => root.handle(JSON.parse(line))
    }

    // niri restarting ends the stream, so it starts again; the first events it sends
    // describe everything afresh.
    onExited: retry.restart()
  }

  Timer {
    id: retry

    interval: 2000
    onTriggered: stream.running = root.available
  }
}
