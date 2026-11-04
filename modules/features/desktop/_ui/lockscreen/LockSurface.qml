import Quickshell
import QtQuick
import QtQuick.Effects
import qs.common

// One output's lock screen: the wallpaper blurred and dimmed, the clock, and
// the password field. It holds a solid background underneath, so nothing shows
// if the wallpaper is missing.
Rectangle {
  id: root

  required property var context

  color: Theme.background

  Image {
    id: wallpaper

    anchors.fill: parent
    visible: false
    source: Settings.wallpaper
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
  }

  MultiEffect {
    anchors.fill: parent
    source: wallpaper
    blurEnabled: true
    blur: 1
    blurMax: 64
    autoPaddingEnabled: false
    visible: wallpaper.status === Image.Ready
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.scrim
  }

  SystemClock {
    id: clock

    precision: SystemClock.Seconds
  }

  Column {
    anchors.centerIn: parent
    spacing: Theme.spaceXl

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Theme.spaceXs

      Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        size: Theme.fontDisplay
        font.weight: Font.Light
      }

      Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "dddd d MMMM")
        size: Theme.fontTitle
        color: Theme.muted
      }
    }

    PasswordField {
      id: field

      anchors.horizontalCenter: parent.horizontalCenter
      text: root.context.password
      busy: root.context.checking
      failed: root.context.failed
      placeholder: {
        if (root.context.checking) return "Checking";
        return root.context.failed ? "Wrong password" : "Password";
      }

      onEdited: root.context.password = text
      onAccepted: root.context.submit()
      Component.onCompleted: takeFocus()

      Connections {
        target: root.context

        function onFailedChanged() {
          if (root.context.failed) field.shake();
        }
      }
    }
  }
}
