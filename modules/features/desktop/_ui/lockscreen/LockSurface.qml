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

    Panel {
      id: field

      property real shake: 0

      anchors.horizontalCenter: parent.horizontalCenter
      implicitWidth: Theme.sizeSidePanel
      implicitHeight: Theme.sizeField
      radius: Theme.radiusLg
      border.width: 2
      border.color: {
        if (root.context.failed) return Theme.danger;
        return input.activeFocus ? Theme.accent : Qt.alpha(Theme.outline, 0.5);
      }

      transform: Translate {
        x: field.shake
      }

      SequentialAnimation {
        id: shaking

        NumberAnimation { target: field; property: "shake"; to: -Theme.spaceSm; duration: Theme.motionFast / 2 }
        NumberAnimation { target: field; property: "shake"; to: Theme.spaceSm; duration: Theme.motionFast / 2 }
        NumberAnimation { target: field; property: "shake"; to: 0; duration: Theme.motionFast / 2 }
      }

      Connections {
        target: root.context

        function onFailedChanged() {
          if (root.context.failed) shaking.restart();
        }
      }

      Icon {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: Theme.spaceLg
        anchors.verticalCenter: parent.verticalCenter
        name: "lock"
        size: Theme.iconMedium
        color: Theme.muted
      }

      TextInput {
        id: input

        anchors.left: icon.right
        anchors.right: parent.right
        anchors.leftMargin: Theme.spaceMd
        anchors.rightMargin: Theme.spaceLg
        anchors.verticalCenter: parent.verticalCenter

        focus: true
        enabled: !root.context.checking
        echoMode: TextInput.Password
        passwordCharacter: "•"
        inputMethodHints: Qt.ImhSensitiveData
        text: root.context.password
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontTitle

        onTextEdited: root.context.password = text
        onAccepted: root.context.submit()
        Component.onCompleted: forceActiveFocus()

        Label {
          anchors.fill: parent
          visible: input.text === ""
          text: {
            if (root.context.checking) return "Checking";
            return root.context.failed ? "Wrong password" : "Password";
          }
          size: Theme.fontTitle
          color: root.context.failed ? Theme.danger : Theme.muted
        }
      }
    }
  }
}
