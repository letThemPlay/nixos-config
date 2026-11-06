import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common
import qs.services

// A short-lived level display on the active output, unless the bar's island can be
// seen to show it instead. Where there's an island but a fullscreen window hides it,
// this goes where the island would be, so a level always appears in one place.
Scope {
  id: root

  readonly property bool shown: Levels.shown && !LiveActivity.showing
  readonly property bool inIslandsPlace: Settings.surfaces.includes("island")

  PanelWindow {
    id: window

    anchors.top: root.inIslandsPlace
    anchors.bottom: !root.inIslandsPlace
    // Room for the panel's shadow, but not above it in the island's place, where the
    // screen's top edge is.
    margins.top: root.inIslandsPlace ? Theme.spaceSm : 0
    margins.bottom: root.inIslandsPlace ? 0 : Theme.spaceXl * 2 - Theme.shadowRoom

    readonly property real panelHeight: root.inIslandsPlace ? Theme.sizeBar : Theme.sizeBar + Theme.spaceSm

    implicitWidth: Theme.sizeSidePanel / 2 + Theme.sizeBar + Theme.shadowRoom * 2
    implicitHeight: panelHeight + Theme.shadowRoom * (root.inIslandsPlace ? 1 : 2)
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

      x: Theme.shadowRoom
      y: root.inIslandsPlace ? 0 : Theme.shadowRoom
      width: parent.width - Theme.shadowRoom * 2
      height: window.panelHeight
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

      Label {
        anchors.left: symbol.right
        anchors.right: parent.right
        anchors.leftMargin: Theme.spaceMd
        anchors.rightMargin: Theme.spaceMd
        anchors.verticalCenter: parent.verticalCenter
        visible: Levels.deviceOnly
        text: Levels.label
      }

      Rectangle {
        id: track

        visible: !Levels.deviceOnly
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

        visible: !Levels.deviceOnly
        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceMd
        anchors.verticalCenter: parent.verticalCenter
        level: Levels.level
      }
    }
  }
}
