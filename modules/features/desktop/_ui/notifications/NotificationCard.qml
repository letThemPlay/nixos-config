import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.common

// One notification, the same in a popup and in the center. Pressing the card
// runs its default action.
Panel {
  id: root

  required property var notification
  readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
  readonly property var defaultAction: (notification?.actions ?? []).find(a => a.identifier === "default") ?? null
  readonly property var buttons: (notification?.actions ?? []).filter(a => a.identifier !== "default")
  readonly property alias hovered: pointer.containsMouse

  // Only a saved record has a time, and says how old it is.
  readonly property string age: {
    const time = notification?.time;
    if (!time) return "";

    const minutes = Math.floor((Date.now() - time) / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return days === 1 ? "Yesterday" : `${days} days ago`;
    if (hours > 0) return hours === 1 ? "An hour ago" : `${hours} hours ago`;
    return minutes > 1 ? `${minutes} minutes ago` : "Just now";
  }

  // Everything but the app name fits a fixed left inset from the icon.
  readonly property int inset: Theme.iconLarge + Theme.spaceMd

  implicitHeight: content.implicitHeight + Theme.spaceMd * 2
  radius: Theme.radiusMd
  border.color: critical ? Theme.danger : Qt.alpha(Theme.outline, 0.5)

  MouseArea {
    id: pointer

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: event => {
      if (event.button === Qt.LeftButton && root.defaultAction)
        root.defaultAction.invoke();
      else
        root.notification?.dismiss();
    }
  }

  AppIcon {
    x: Theme.spaceMd
    y: Theme.spaceMd
    name: root.notification?.image || root.notification?.appIcon || root.notification?.desktopEntry || ""
  }

  Column {
    id: content

    x: Theme.spaceMd + root.inset
    y: Theme.spaceMd
    width: root.width - x - Theme.spaceMd
    spacing: Theme.spaceXs

    Item {
      width: parent.width
      height: Math.max(appName.implicitHeight, close.implicitHeight)

      Label {
        id: appName

        anchors.left: parent.left
        anchors.right: ageLabel.left
        anchors.rightMargin: root.age === "" ? 0 : Theme.spaceSm
        anchors.verticalCenter: parent.verticalCenter
        text: root.notification?.appName ?? ""
        size: Theme.fontSmall
        color: Theme.muted
      }

      Label {
        id: ageLabel

        anchors.right: close.left
        anchors.rightMargin: root.age === "" ? 0 : Theme.spaceXs
        anchors.verticalCenter: parent.verticalCenter
        text: root.age
        size: Theme.fontSmall
        color: Theme.muted
      }

      IconButton {
        id: close

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        icon: "close"
        onClicked: root.notification?.dismiss()
      }
    }

    Label {
      width: parent.width
      text: root.notification?.summary ?? ""
      size: Theme.fontTitle
      font.weight: Font.DemiBold
      wrapMode: Text.Wrap
      maximumLineCount: 2
    }

    Label {
      width: parent.width
      visible: text !== ""
      text: root.notification?.body ?? ""
      color: Theme.muted
      wrapMode: Text.Wrap
      maximumLineCount: 6
    }

    Flow {
      width: parent.width
      spacing: Theme.spaceXs
      visible: root.buttons.length > 0

      Repeater {
        model: root.buttons

        Pressable {
          required property var modelData

          implicitWidth: actionLabel.implicitWidth + Theme.spaceMd * 2
          implicitHeight: actionLabel.implicitHeight + Theme.spaceSm
          // Over any card colour: popups sit on surface, the center on surfaceRaised.
          color: Qt.alpha(Theme.outline, hovered ? 0.9 : 0.5)
          onClicked: modelData.invoke()

          Label {
            id: actionLabel

            anchors.centerIn: parent
            text: parent.modelData.text
          }
        }
      }
    }
  }
}
