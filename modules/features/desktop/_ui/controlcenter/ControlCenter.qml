import Quickshell.Io
import QtQuick
import qs.common
import qs.notifications
import qs.quicksettings

// Quick settings and notifications together, as two panels under the bar's right
// island: settings sized to what they hold, and notifications below, taking what room
// is left. A host drawing only one of them gets just that panel.
Overlay {
  id: root

  surface: "controlcenter"

  readonly property bool hasSettings: Settings.surfaces.includes("quicksettings")
  readonly property bool hasNotifications: Settings.surfaces.includes("notifier")

  IpcHandler {
    target: "controlcenter"

    function toggle(): void {
      Ui.toggle("controlcenter");
    }
  }

  Item {
    id: stack

    readonly property real topEdge: Theme.sizeBar + Theme.spaceSm * 2

    x: root.width - width - Theme.spaceSm
    y: topEdge - (1 - root.progress) * Theme.spaceXl
    width: Theme.sizeSidePanel
    height: root.height - topEdge - Theme.spaceSm
    opacity: root.progress

    SettingsPanel {
      id: settings

      width: parent.width
      height: Math.min(implicitHeight, stack.height)
      visible: root.hasSettings
      shown: root.shown
    }

    NotificationsPanel {
      y: root.hasSettings ? settings.height + Theme.spaceSm : 0
      width: parent.width
      height: Math.min(implicitHeight, stack.height - y)
      visible: root.hasNotifications
    }
  }
}
