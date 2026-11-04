import Quickshell
import QtQuick
import qs.common

BarItem {
  text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }
}
