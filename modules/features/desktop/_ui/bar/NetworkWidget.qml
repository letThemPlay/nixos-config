import qs.common
import qs.services

// The connection carrying the default route. Clicking opens the wireless UI
// where the host has one.
BarItem {
  icon: Network.icon
  text: Network.kind === "wifi" ? Network.name : ""
  tint: Network.kind === "none" ? Theme.warning : foreground
  textWidth: Theme.sizeSidePanel / 3
  onClicked: Run.command("networkUi")
}
