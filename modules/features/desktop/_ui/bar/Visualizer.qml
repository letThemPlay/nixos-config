import Quickshell.Io
import QtQuick
import qs.common

// Bars for what the default output is playing, bass on the left and treble on the
// right, from the visualizer command. It only runs while active.
Row {
  id: root

  property bool active: false

  // As many as the command's config asks for.
  property var levels: [0, 0, 0, 0, 0, 0, 0]

  // Each band's recent peak. cava scales every band to the loudest, so with this few
  // bars one band can flatten the rest, so each is shown against its own. The peak falls
  // over a few seconds, and has a lower limit so near silence isn't blown up to fill.
  property var peaks: [0, 0, 0, 0, 0, 0, 0]

  function show(bands) {
    peaks = bands.map((band, index) => Math.max(band, peaks[index] * 0.99, 0.03));
    levels = bands.map((band, index) => band / peaks[index]);
  }

  spacing: Theme.spaceXs / 2

  onActiveChanged: {
    if (active) return;

    levels = [0, 0, 0, 0, 0, 0, 0];
    peaks = [0, 0, 0, 0, 0, 0, 0];
  }

  Process {
    command: Settings.commands.visualizer ?? []
    running: root.active && command.length > 0

    // One frame a line: each band from 0 to 100, followed by a semicolon.
    stdout: SplitParser {
      onRead: frame => {
        const bands = frame.split(";").filter(band => band !== "").map(band => Number(band) / 100);
        if (bands.length === root.levels.length) root.show(bands);
      }
    }
  }

  Repeater {
    model: root.levels.length

    Rectangle {
      required property int index

      anchors.verticalCenter: parent.verticalCenter
      width: Theme.spaceXs
      height: width + (Theme.iconSmall - width) * root.levels[index]
      radius: width / 2
      color: Theme.accent
    }
  }
}
