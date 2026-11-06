import Quickshell
import QtQuick
import qs.common
import qs.services

// The date and time. With the center island, the month is in its card, so pressing
// this opens it there, as Mod+Shift+D does; otherwise in the calendar's own panel.
BarItem {
  readonly property bool hasIsland: Settings.surfaces.includes("island")

  text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
  selected: hasIsland ? Ui.open === "island" && LiveActivity.isFocused && LiveActivity.focusedOn === "month" : Ui.open === "calendar"

  onClicked: {
    if (hasIsland) {
      if (Ui.open === "island") LiveActivity.collapse();
      else LiveActivity.focusOn("month", true);
    } else if (Settings.surfaces.includes("calendar")) {
      Ui.toggle("calendar");
    }
  }

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }
}
