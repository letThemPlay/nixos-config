pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// Wi-Fi through the helper command, as Quickshell's Networking module only speaks
// NetworkManager. It's asked while a panel is watching and not otherwise.
Singleton {
  id: root

  readonly property bool usable: Settings.surfaces.includes("wifi") && Run.has("wifi")

  property bool watching: false

  property bool present: false
  property bool powered: false
  property bool scanning: false
  property var networks: []

  // Why the last list failed, or "": not-allowed, unavailable and so on.
  property string problem: ""

  // The network being joined, and what went wrong with the last one to fail.
  property string joining: ""
  property string failedPath: ""
  property string failedCode: ""

  property string passphrase: ""

  signal joinFailed(string path, string code)

  function argv(args) {
    return Settings.commands.wifi.concat(args);
  }

  function refresh() {
    if (usable && !list.running) list.running = true;
  }

  // The panel's rows act on one thing at a time, so a second press just waits out
  // the first.
  function act(args) {
    if (!usable || action.running) return;

    action.command = argv(args);
    action.running = true;
  }

  function clearFailure() {
    failedPath = "";
    failedCode = "";
  }

  function join(path, secret) {
    if (!usable || joiner.running) return;

    clearFailure();
    joining = path;
    passphrase = secret;
    joiner.command = argv(["connect", path]);
    joiner.running = true;
  }

  function changed() {
    refresh();
    Network.refresh();
  }

  onWatchingChanged: {
    if (!watching) return;

    refresh();
    act(["scan"]);
  }

  Timer {
    interval: 3000
    running: root.watching
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: list

    command: root.usable ? root.argv(["list"]) : []

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const state = JSON.parse(text);

          root.problem = state.ok ? "" : state.error;
          root.present = state.present ?? false;
          root.powered = state.powered ?? false;
          root.scanning = state.scanning ?? false;
          root.networks = state.networks ?? [];
        } catch (error) {
          root.problem = "unavailable";
        }
      }
    }
  }

  Process {
    id: action

    stdout: StdioCollector {
      onStreamFinished: root.changed()
    }
  }

  // The passphrase goes over stdin, and only for as long as it takes to write it.
  Process {
    id: joiner

    stdinEnabled: true

    onStarted: {
      write(root.passphrase + "\n");
      root.passphrase = "";
    }

    stdout: StdioCollector {
      onStreamFinished: {
        const path = root.joining;
        root.joining = "";

        let code = "failed";
        try {
          const reply = JSON.parse(text);
          code = reply.ok ? "" : reply.error;
        } catch (error) {
          code = "failed";
        }

        if (code !== "") {
          root.failedPath = path;
          root.failedCode = code;
          root.joinFailed(path, code);
        }

        root.changed();
      }
    }
  }
}
