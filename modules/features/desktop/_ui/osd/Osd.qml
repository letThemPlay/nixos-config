import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common
import qs.services

// A short-lived level display at the bottom of the active output, unless the bar's
// island can be seen to show it instead.
Scope {
  id: root

  readonly property bool shown: Levels.shown && !LiveActivity.showing

  PanelWindow {
    id: window

    anchors.bottom: true
    margins.bottom: Theme.spaceXl * 2

    implicitWidth: Theme.sizeSidePanel / 2 + Theme.sizeBar
    implicitHeight: Theme.sizeBar + Theme.spaceSm
    visible: root.shown || panel.opacity > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Never takes a press or a key from what is underneath.
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ltp-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Panel {
      id: panel

      anchors.fill: parent
      opacity: root.shown ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: Theme.motionNormal }
      }

      Icon {
        id: symbol

        anchors.left: parent.left
        anchors.leftMargin: Theme.spaceMd
        anchors.verticalCenter: parent.verticalCenter
        name: Levels.icon
        size: Theme.iconMedium
        color: Levels.warn ? Theme.warning : Theme.text
      }

      Rectangle {
        id: track

        anchors.left: symbol.right
        anchors.right: percent.left
        anchors.leftMargin: Theme.spaceMd
        anchors.rightMargin: Theme.spaceMd
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.spaceXs
        radius: height / 2
        color: Qt.alpha(Theme.outline, 0.5)

        Rectangle {
          width: parent.width * Levels.level
          height: parent.height
          radius: parent.radius
          color: Levels.warn ? Theme.warning : Theme.accent

          Behavior on width {
            NumberAnimation { duration: Theme.motionFast }
          }
        }
      }

      Percent {
        id: percent

        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceMd
        anchors.verticalCenter: parent.verticalCenter
        level: Levels.level
      }
    }
  }
}
