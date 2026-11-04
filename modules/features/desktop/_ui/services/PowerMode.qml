pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import qs.common

// The active power profile, by name. Only offered where the host manages them:
// setting one without the daemon does nothing.
Singleton {
  readonly property bool available: Settings.powerProfiles
  readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile

  readonly property string current: {
    if (PowerProfiles.profile === PowerProfile.PowerSaver) return "saver";
    return PowerProfiles.profile === PowerProfile.Performance ? "performance" : "balanced";
  }

  function choose(name) {
    if (name === "saver") PowerProfiles.profile = PowerProfile.PowerSaver;
    else if (name === "performance") PowerProfiles.profile = PowerProfile.Performance;
    else PowerProfiles.profile = PowerProfile.Balanced;
  }
}
