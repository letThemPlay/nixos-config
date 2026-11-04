import qs.common

BarItem {
  icon: "poweroff"
  selected: Ui.open === "power"
  onClicked: Ui.toggle("power")
}
