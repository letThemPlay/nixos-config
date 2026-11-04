pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

// The machine's battery, as the surfaces need it.
Singleton {
  readonly property var device: UPower.displayDevice

  // Before UPower answers the percentage reads 0, which must not look like an
  // empty battery.
  readonly property bool present: (device?.ready ?? false) && (device?.isLaptopBattery ?? false)
  readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
  readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged
  readonly property real timeToEmpty: device?.timeToEmpty ?? 0

  readonly property string icon: {
    if (charging) return "batteryCharging";
    if (percent >= 90) return "batteryFull";
    if (percent >= 50) return "batteryHigh";
    return percent >= 20 ? "batteryMedium" : "batteryLow";
  }
}
