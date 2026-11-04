import Quickshell
import Quickshell.Wayland
import QtQuick

// A transient surface above everything on the focused output. It holds the
// keyboard while open, and a press outside its content dismisses it; progress
// runs 0 -> 1 as it opens, for the content's own entrance. No screen is
// chosen, so the compositor places it on the active output.
PanelWindow {
  id: root

  required property string surface
  property bool scrimmed: false
  readonly property bool shown: Ui.open === surface
  property real progress: shown ? 1 : 0

  default property alias content: stage.data

  visible: shown || progress > 0
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "ltp-" + surface
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Behavior on progress {
    NumberAnimation {
      duration: Theme.motionNormal
      easing.type: Easing.OutCubic
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.scrim
    visible: root.scrimmed
    opacity: root.progress
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Ui.close()
  }

  FocusScope {
    id: stage

    anchors.fill: parent
    focus: root.shown

    Keys.onEscapePressed: Ui.close()
  }
}
