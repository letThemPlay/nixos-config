import qs.common
import qs.services

// Always there on a host with tunnels, like the network item: which one carries
// all traffic, or how many are up, and a crossed-out key while none is. Clicking
// opens the tunnels panel, where they are switched.
BarItem {
  readonly property bool up: Tunnels.active.length > 0

  shown: Tunnels.available
  filled: up
  icon: Tunnels.full ? "tunnelFull" : up ? "tunnel" : "tunnelOff"
  text: Tunnels.full ? Tunnels.full.label : Tunnels.active.length > 1 ? String(Tunnels.active.length) : Tunnels.active[0]?.label ?? ""
  textWidth: Theme.sizeSidePanel / 3
  tint: up ? Theme.success : foreground
  selected: Ui.open === "tunnels"
  onClicked: Ui.toggle("tunnels")
}
