import qs.common

BarItem {
  icon: "settings"
  selected: Ui.open === "quicksettings"
  onClicked: Ui.toggle("quicksettings")
}
