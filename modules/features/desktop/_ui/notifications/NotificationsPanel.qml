import Quickshell
import QtQuick
import qs.common

// The notifications in the control center, under its settings. It's as tall as what it
// holds, and scrolls once that's more than the room the control center gives it.
Panel {
  id: root

  readonly property bool empty: Notifications.history.length === 0 && Notifications.earlier.length === 0

  implicitHeight: list.y + cards.implicitHeight + Theme.spaceMd

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

      // Nothing to show takes only the room it needs.
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        topPadding: Theme.spaceSm
        bottomPadding: Theme.spaceSm
        spacing: Theme.spaceSm
        visible: root.empty

        Icon {
          anchors.verticalCenter: parent.verticalCenter
          name: Notifications.doNotDisturb ? "notificationsPaused" : "notifications"
          size: Theme.iconMedium
          color: Theme.muted
        }

        Label {
          anchors.verticalCenter: parent.verticalCenter
          text: Notifications.doNotDisturb ? "Do not disturb is on" : "No notifications"
          color: Theme.muted
        }
      }
    }
  }
}
