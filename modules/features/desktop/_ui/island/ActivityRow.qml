import QtQuick
import qs.common
import qs.services

// One background activity in the island's card: what it is, how far along, and for a
// timer, the way to cancel it. Looks its values up by key, as they change every second.
Row {
  id: root

  required property string activityKey

  readonly property var activity: Activities.item(activityKey)

  spacing: Theme.spaceSm

  Icon {
    anchors.verticalCenter: parent.verticalCenter
    name: root.activity?.icon ?? "timer"
    size: Theme.iconSmall
    color: Theme.accent
  }

  Column {
    anchors.verticalCenter: parent.verticalCenter
    width: root.width - Theme.iconSmall - root.spacing * (cancel.visible ? 2 : 1) - (cancel.visible ? cancel.width : 0)
    spacing: Theme.spaceXs

    Label {
      width: parent.width
      text: root.activity?.name ?? ""
    }

    Rectangle {
      width: parent.width
      height: Theme.spaceXs
      radius: height / 2
      color: Qt.alpha(Theme.outline, 0.5)
      visible: (root.activity?.fraction ?? -1) >= 0

      Rectangle {
        width: parent.width * Math.max(0, root.activity?.fraction ?? 0)
        height: parent.height
        radius: parent.radius
        color: Theme.accent

        Behavior on width {
          NumberAnimation { duration: Theme.motionNormal }
        }
      }
    }

    Label {
      width: parent.width
      text: root.activity?.detail ?? ""
      size: Theme.fontSmall
      color: Theme.muted
    }
  }

  IconButton {
    id: cancel

    anchors.verticalCenter: parent.verticalCenter
    visible: root.activity?.timerId !== undefined
    icon: "close"
    onClicked: Activities.cancelTimer(root.activity.timerId)
  }
}
