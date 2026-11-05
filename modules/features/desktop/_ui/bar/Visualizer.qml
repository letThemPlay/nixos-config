import Quickshell.Services.Pipewire
import QtQuick
import qs.common

// Bars pulsing with what the default output is playing, spreading from the middle as
// each reading ages. PipeWire reports a level, not frequencies, so this is the sound's
// loudness over time rather than a spectrum. It only listens while active.
Row {
  id: root

  property bool active: false

  // Newest first, and as many as there are bars from the middle out.
  property var readings: [0, 0, 0, 0]

  spacing: Theme.spaceXs / 2

  onActiveChanged: {
    if (!active) readings = [0, 0, 0, 0];
  }

  PwNodePeakMonitor {
    id: monitor

    node: Pipewire.defaultAudioSink
    enabled: root.active
  }

  Timer {
    interval: Theme.motionFast
    running: root.active
    repeat: true
    // Peaks are linear, where hearing isn't, so quiet sound would barely register.
    onTriggered: root.readings = [Math.sqrt(monitor.peak)].concat(root.readings.slice(0, -1))
  }

  Repeater {
    model: 7

    Rectangle {
      required property int index

      anchors.verticalCenter: parent.verticalCenter
      width: Theme.spaceXs
      height: Math.max(width, Theme.iconSmall * root.readings[Math.abs(index - 3)])
      radius: width / 2
      color: Theme.accent

      Behavior on height {
        NumberAnimation { duration: Theme.motionFast }
      }
    }
  }
}
