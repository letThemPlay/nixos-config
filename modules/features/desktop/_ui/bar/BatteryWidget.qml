import qs.common
import qs.services

// Hidden on machines without a battery. It turns warning and danger at the same
// levels the alerts fire at.
BarItem {
  shown: Battery.present
  filled: true
  icon: Battery.icon
  text: Battery.percent + "%"
  tint: {
    if (Battery.charging) return Theme.success;
    if (Battery.percent <= Settings.batteryLevels.critical) return Theme.danger;
    return Battery.percent <= Settings.batteryLevels.low ? Theme.warning : foreground;
  }
}
