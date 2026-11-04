import qs.common

BarItem {
  icon: "launcher"
  selected: Ui.open === "launcher"
  onClicked: Ui.toggle("launcher")
}
