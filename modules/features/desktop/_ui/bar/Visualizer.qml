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
  // the scale, so movement is where a reading sits within this. Each edge jumps to a new
  // extreme and drifts back over a couple of seconds, to follow a track's changes.
  property real floor: 0
  property real ceiling: 0

  // How loud the track has been over a longer stretch, for how present this reading is.
  property real reference: 0

  // Movement alone would collapse whenever music holds steady, as the floor catches up
  // with it. So bars stand on this share of their height while there's sound, and
  // movement takes them the rest of the way. Only silence reaches the minimum.
  readonly property real base: 0.55

  function shaped(peak) {
    floor = Math.min(peak, floor + (peak - floor) * 0.05);
    ceiling = Math.max(peak, ceiling + (peak - ceiling) * 0.05);
    reference = Math.max(peak, reference + (peak - reference) * 0.005);

    if (reference < 0.01) return 0;

    const presence = peak / reference;
    const movement = Math.pow((peak - floor) / Math.max(ceiling - floor, 0.1), 1.5);

    return presence * (base + (1 - base) * movement);
  }

  spacing: Theme.spaceXs / 2

  onActiveChanged: {
    if (active) return;

    readings = [0, 0, 0, 0];
    floor = 0;
    ceiling = 0;
    reference = 0;
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
