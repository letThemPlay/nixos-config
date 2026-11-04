import QtQuick

// A level control, 0 to 1, drawn like the level display. It only reports where
// the pointer put it: the surface decides what to apply, and value catches up.
Item {
  id: root

  property real value: 0
  property real minimum: 0

  // Still holds its level, but warns that the level isn't in effect.
  property bool muted: false

  // While dragging it follows the pointer, not a value still catching up.
  readonly property real shownValue: mouse.pressed ? pointerValue : value
  property real pointerValue: 0

  signal moved(real value)

  function report(next) {
    const clamped = Math.max(minimum, Math.min(1, next));
    pointerValue = clamped;
    moved(clamped);
  }

  implicitHeight: Theme.sizeBarItem

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: Theme.spaceXs
    radius: height / 2
    color: Qt.alpha(Theme.outline, 0.5)

    Rectangle {
      width: parent.width * root.shownValue
      height: parent.height
      radius: parent.radius
      color: root.muted ? Theme.warning : Theme.accent
    }
  }

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    x: (root.width - width) * root.shownValue
    width: Theme.iconSmall
    height: width
    radius: width / 2
    color: root.muted ? Theme.warning : Theme.accent
    border.width: 2
    border.color: Theme.surface
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onPressed: event => root.report(event.x / root.width)
    onPositionChanged: event => {
      if (pressed) root.report(event.x / root.width);
    }
    onWheel: event => root.report(root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))
  }
}
