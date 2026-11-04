import Quickshell.Services.UPower
import qs.common

// Hidden on machines without a battery.
BarItem {
  readonly property var device: UPower.displayDevice
  readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
  readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged

  shown: device?.isLaptopBattery ?? false
  filled: true
  icon: {
    if (charging) return "batteryCharging";
    if (percent >= 90) return "batteryFull";
    if (percent >= 50) return "batteryHigh";
    return percent >= 20 ? "batteryMedium" : "batteryLow";
  }
  text: percent + "%"
  tint: {
    if (charging) return Theme.success;
    if (percent <= 15) return Theme.danger;
    return percent <= 30 ? Theme.warning : foreground;
  }
}
