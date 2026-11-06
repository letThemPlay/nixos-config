import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// A month view under the bar's clock, on whichever side holds it, always opening on
// the current month.
Overlay {
  id: root

  surface: "calendar"

  readonly property bool onLeft: Settings.barLeft.includes("clock")

  onShownChanged: {
    if (shown) view.showCurrent();
  }

  IpcHandler {
    target: "calendar"

    function toggle(): void {
      Ui.toggle("calendar");
    }
  }

  Panel {
    id: panel

    x: root.onLeft ? Theme.spaceSm : root.width - width - Theme.spaceSm
    y: Theme.sizeBar + Theme.spaceSm * 2 - (1 - root.progress) * Theme.spaceXl
    width: view.implicitWidth + Theme.spaceLg * 2
    height: view.implicitHeight + Theme.spaceLg * 2
    opacity: root.progress
    focus: true

    Keys.onLeftPressed: view.move(-1)
    Keys.onRightPressed: view.move(1)

    // Presses inside the panel must not reach the overlay's dismiss area.
    MouseArea {
      anchors.fill: parent
      onWheel: event => view.scroll(event.angleDelta.y)
    }

    MonthView {
      id: view

      anchors.centerIn: parent
    }
  }
}
