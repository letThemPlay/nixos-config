import QtQuick

// A control's background and pointer handling: the same hover, press and
// selected states everywhere. Children are the control's content.
Rectangle {
  id: root

  property bool selected: false
  property bool danger: false
  // For a row in a scrolling list, where the wheel belongs to the list.
  property bool passesWheel: false
  readonly property alias hovered: mouse.containsMouse
  readonly property alias pressed: mouse.pressed
  readonly property color foreground: {
    if (danger) return Theme.accentText;
    return selected ? Theme.accentText : Theme.text;
  }

  signal clicked(int button)
  signal scrolled(int delta)

  radius: Theme.radiusMd
  color: {
    if (danger) return Theme.danger;
    if (selected) return Theme.accent;
    if (pressed) return Theme.outline;
    if (hovered) return Theme.surfaceRaised;
    return "transparent";
  }

  Behavior on color {
    ColorAnimation { duration: Theme.motionFast }
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: event => root.clicked(event.button)
    onWheel: event => {
      event.accepted = !root.passesWheel;
      if (!root.passesWheel) root.scrolled(event.angleDelta.y);
    }
  }
}
