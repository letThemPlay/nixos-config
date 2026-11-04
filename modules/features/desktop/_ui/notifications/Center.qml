import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// The notification center. It slides in from the left edge: niri scrolls
// columns horizontally and keeps new windows coming in on the right, so the
// left is the edge that stays out of the way of the layout.
Overlay {
  id: root

  surface: "notifications"

  Panel {
    id: panel

    y: Theme.sizeBar + Theme.spaceSm * 2
    x: Theme.spaceSm - (1 - root.progress) * (width + Theme.spaceSm)
    width: Theme.sizeSidePanel
    height: root.height - y - Theme.spaceSm

    // Presses inside the panel must not reach the overlay's dismiss area.
    MouseArea {
      anchors.fill: parent
    }

    Row {
      id: header

      x: Theme.spaceLg
      y: Theme.spaceMd
      width: parent.width - Theme.spaceLg * 2
      spacing: Theme.spaceXs

      Label {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - doNotDisturb.width - clear.width - parent.spacing * 2
        text: "Notifications"
        size: Theme.fontHeading
        font.weight: Font.DemiBold
      }

      IconButton {
        id: doNotDisturb

        icon: "notificationsPaused"
        iconSize: Theme.iconMedium
        selected: Notifications.doNotDisturb
        onClicked: Notifications.doNotDisturb = !Notifications.doNotDisturb
      }

      IconButton {
        id: clear

        icon: "clearAll"
        iconSize: Theme.iconMedium
        onClicked: Notifications.clearAll()
      }
    }

    Flickable {
      id: list

      x: Theme.spaceMd
      y: header.y + header.height + Theme.spaceMd
      width: parent.width - Theme.spaceMd * 2
      height: parent.height - y - Theme.spaceMd
      clip: true
      contentHeight: cards.implicitHeight
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: cards

        width: list.width
        spacing: Theme.spaceSm

        Repeater {
          model: ScriptModel {
            values: Notifications.history
          }

          NotificationCard {
            required property var modelData

            notification: modelData
            width: cards.width
            color: Theme.surfaceRaised
          }
        }

        Label {
          visible: Notifications.earlier.length > 0
          leftPadding: Theme.spaceXs
          topPadding: Notifications.history.length > 0 ? Theme.spaceMd : 0
          text: "Earlier"
          color: Theme.muted
          font.weight: Font.DemiBold
        }

        Repeater {
          model: ScriptModel {
            values: Notifications.earlier
          }

          NotificationCard {
            required property var modelData

            notification: modelData
            width: cards.width
            color: Theme.surfaceRaised
          }
        }
      }
    }

    Column {
      anchors.centerIn: parent
      spacing: Theme.spaceSm
      visible: Notifications.history.length === 0 && Notifications.earlier.length === 0

      Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        name: Notifications.doNotDisturb ? "notificationsPaused" : "notifications"
        size: Theme.iconHuge
        color: Theme.muted
      }

      Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Notifications.doNotDisturb ? "Do not disturb is on" : "No notifications"
        color: Theme.muted
      }
    }
  }
}
