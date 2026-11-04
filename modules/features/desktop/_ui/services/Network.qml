pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// The network state, from a small status command. Quickshell's Networking
// module only speaks NetworkManager; the fleet runs networkd and iwd.
Singleton {
  id: root

  property string kind: "none"
  property string name: ""
  property int strength: 0

  readonly property string icon: {
    if (kind === "wired") return "wired";
    if (kind !== "wifi") return "wifiOff";
    if (strength >= 66) return "wifiFull";
    return strength >= 33 ? "wifiMedium" : "wifiLow";
  }

  Process {
    id: status

    command: Settings.commands.networkStatus ?? []

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const state = JSON.parse(text);
          root.kind = state.kind;
          root.name = state.name;
          root.strength = state.strength;
        } catch (error) {
          root.kind = "none";
        }
      }
    }
  }

  Timer {
    interval: 5000
    running: status.command.length > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: status.running = true
  }
}
