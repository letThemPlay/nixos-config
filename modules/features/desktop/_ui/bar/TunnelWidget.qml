import qs.common
import qs.services

// Only there while a tunnel is up: which one carries all traffic, or how many
// are up. Clicking opens the control center, where they are switched.
BarItem {
  shown: Tunnels.active.length > 0
  filled: true
  icon: Tunnels.full ? "tunnelFull" : "tunnel"
  text: Tunnels.full ? Tunnels.full.label : Tunnels.active.length > 1 ? String(Tunnels.active.length) : Tunnels.active[0]?.label ?? ""
  textWidth: Theme.sizeSidePanel / 3
  tint: Theme.success
  selected: Ui.open === "controlcenter"
  onClicked: Ui.toggle("controlcenter")
}
