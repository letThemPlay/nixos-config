import qs.common
import qs.services

// The connection carrying the default route. Clicking opens the wireless UI
// where the host has one.
BarItem {
  icon: {
    if (Network.kind === "wired") return "wired";
    if (Network.kind !== "wifi") return "wifiOff";
    if (Network.strength >= 66) return "wifiFull";
    return Network.strength >= 33 ? "wifiMedium" : "wifiLow";
  }
  text: Network.kind === "wifi" ? Network.name : ""
  tint: Network.kind === "none" ? Theme.warning : foreground
  textWidth: Theme.sizeSidePanel / 3
  onClicked: Run.command("networkUi")
}
