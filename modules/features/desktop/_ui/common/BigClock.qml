import Quickshell
import QtQuick

// The large time and date above a password field.
Column {
  spacing: Theme.spaceXs

  SystemClock {
    id: clock

    precision: SystemClock.Seconds
  }

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
