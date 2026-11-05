import Quickshell
import QtQuick
import qs.common

BarItem {
  text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
  selected: Ui.open === "calendar"

  onClicked: {
    if (Settings.surfaces.includes("calendar")) Ui.toggle("calendar");
  }

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }
}
