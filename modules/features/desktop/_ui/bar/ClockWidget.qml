import Quickshell
import QtQuick
import qs.common

// The date and time. Pressing it drops the month down beneath it, as Mod+Shift+D does.
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
