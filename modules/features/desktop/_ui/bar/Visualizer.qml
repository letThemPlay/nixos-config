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

  // The range the sound has been moving in lately. Loud music rarely leaves the top of
  // the scale, so bars follow where a reading sits within this rather than how loud it
  // is. Each edge jumps to a new extreme and drifts back over a few seconds, the
  // ceiling faster, so a quieter passage isn't left flat while it comes down.
  property real floor: 0
  property real ceiling: 0

  function shaped(peak) {
    floor = Math.min(peak, floor + (peak - floor) * 0.02);
    ceiling = Math.max(peak, ceiling + (peak - ceiling) * 0.05);

    // A narrow range is sound holding steady or nearly silent, not worth filling the
    // bars for. The curve keeps the bars low between beats.
    return Math.pow((peak - floor) / Math.max(ceiling - floor, 0.1), 1.5);
  }

  spacing: Theme.spaceXs / 2

  onActiveChanged: {
    if (active) return;

    readings = [0, 0, 0, 0];
    floor = 0;
    ceiling = 0;
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
    onTriggered: root.readings = [root.shaped(monitor.peak)].concat(root.readings.slice(0, -1))
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
