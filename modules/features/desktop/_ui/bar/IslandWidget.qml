import QtQuick
import Quickshell
import qs.common
import qs.notifications
import qs.services

// The center island's compact form. It grows to fit what LiveActivity says is
// happening, up to the room the side islands leave. Pressing expands it into the
// card; a right click skips a track or dismisses a notification.
Pressable {
  id: root

  property real room: Theme.sizeSidePanel

  readonly property bool shown: true
  readonly property string kind: LiveActivity.kind

  // A critical notification shows as any other, only insisting.
  readonly property string face: kind === "critical" ? "notification" : kind
  readonly property Item active: ({
    level: level,
    notification: notification,
    recording: recording,
    media: media,
    clock: clockLabel
  })[face]

  // Nothing else on the bar may hide that the screen is being recorded.
  readonly property bool marked: Recorder.active && kind !== "recording"
  readonly property real wanted: active.implicitWidth + (marked ? mark.width + Theme.spaceSm : 0) + Theme.spaceSm * 2

  implicitHeight: Theme.sizeBarItem
  implicitWidth: Math.min(wanted, room)
  clip: true

  onImplicitWidthChanged: LiveActivity.compactWidth = implicitWidth + Theme.sizeBar - Theme.sizeBarItem

  Behavior on implicitWidth {
    NumberAnimation { duration: LiveActivity.motion; easing.type: Easing.OutCubic }
  }

  onClicked: button => {
    if (button !== Qt.RightButton) LiveActivity.press();
    else if (face === "media") Media.player?.next();
    else if (face === "notification") LiveActivity.notification?.dismiss();
  }

  component Face: Row {
    required property string activity

    anchors.centerIn: stage
    anchors.horizontalCenterOffset: root.marked ? (mark.width + Theme.spaceSm) / 2 : 0
    spacing: Theme.spaceSm
    opacity: root.face === activity ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.motionFast }
    }
  }

  Rectangle {
    id: mark

    anchors.left: parent.left
    anchors.leftMargin: Theme.spaceSm
    anchors.verticalCenter: parent.verticalCenter
    width: Theme.spaceSm
    height: width
    radius: width / 2
    color: Theme.danger
    visible: root.marked
  }

  Item {
    id: stage

    anchors.fill: parent
  }

  Face {
    id: level

    activity: "level"

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      name: Levels.icon
      size: Theme.iconSmall
      color: Levels.warn ? Theme.warning : root.foreground
    }

    Label {
      anchors.verticalCenter: parent.verticalCenter
      visible: Levels.label !== ""
      width: Math.min(implicitWidth, Theme.sizeSidePanel / 2)
      text: Levels.label
      size: Levels.deviceOnly ? Theme.fontBody : Theme.fontSmall
      color: Levels.deviceOnly ? root.foreground : Theme.muted
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      visible: !Levels.deviceOnly
      width: Theme.sizeSidePanel / 3
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
      anchors.verticalCenter: parent.verticalCenter
      visible: !Levels.deviceOnly
      level: Levels.level
    }
  }

  Face {
    id: notification

    activity: "notification"

    AppIcon {
      id: notificationIcon

      anchors.verticalCenter: parent.verticalCenter
      size: Theme.iconSmall
      name: {
        const current = LiveActivity.notification;
        return current?.image || current?.appIcon || current?.desktopEntry || "";
      }
    }

    Label {
      id: appName

      anchors.verticalCenter: parent.verticalCenter
      visible: text !== ""
      text: LiveActivity.notification?.appName ?? ""
      size: Theme.fontSmall
      color: Theme.muted
    }

    Label {
      id: summary

      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, Theme.sizeSidePanel / 2)
      text: LiveActivity.notification?.summary ?? ""
      color: root.kind === "critical" ? Theme.danger : root.foreground
      font.weight: root.kind === "critical" ? Font.DemiBold : Font.Normal
    }

    // One line of the body, in whatever room the rest leaves.
    Label {
      readonly property real room: root.room - Theme.spaceSm * 2 - notificationIcon.width - appName.width - summary.width - count.width - notification.spacing * 4

      anchors.verticalCenter: parent.verticalCenter
      visible: text !== "" && room > Theme.iconLarge
      width: Math.min(implicitWidth, Math.min(room, Theme.sizeSidePanel / 2))
      text: (LiveActivity.notification?.body ?? "").split("\n")[0]
      color: Theme.muted
    }

    Label {
      id: count

      anchors.verticalCenter: parent.verticalCenter
      visible: Notifications.count > 1
      text: Notifications.count
      size: Theme.fontSmall
      color: Theme.muted
    }
  }

  Face {
    id: recording

    activity: "recording"

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      name: "recording"
      filled: true
      size: Theme.iconSmall
      color: Theme.danger
    }

    Label {
      anchors.verticalCenter: parent.verticalCenter
      text: Recorder.elapsed
      color: Theme.danger
    }
  }

  Face {
    id: media

    activity: "media"
    spacing: Theme.spaceXs

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      implicitWidth: Theme.iconMedium
      icon: Media.playing ? "mediaPause" : "mediaPlay"
      onClicked: Media.player?.togglePlaying()
    }

    Label {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, Theme.sizeSidePanel)
      text: Media.player?.trackTitle ?? ""
      color: root.foreground
    }

    Visualizer {
      anchors.verticalCenter: parent.verticalCenter
      active: root.kind === "media" && LiveActivity.showing && Ui.open !== "island"
    }
  }

  Face {
    id: clockFace

    activity: "clock"

    Label {
      id: clockLabel

      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
      color: root.foreground
    }
  }

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }
}
