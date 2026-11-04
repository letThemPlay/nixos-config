import qs.common
import qs.services

// The connection carrying the default route. Clicking opens the Wi-Fi panel, or
// the wireless UI on a host with no panel for its backend.
BarItem {
  icon: Network.icon
  text: Network.kind === "wifi" ? Network.name : ""
  tint: Network.kind === "none" ? Theme.warning : foreground
  textWidth: Theme.sizeSidePanel / 3
  selected: Ui.open === "wifi"
  onClicked: {
    if (Wifi.usable) Ui.toggle("wifi");
    else Run.command("networkUi");
  }
}
