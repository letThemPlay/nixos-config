import Quickshell
import QtQuick
import qs.common

// Warns once per discharge at each level, through the notification daemon, so
// the alerts are ordinary notifications. Starting below a level counts as
// reaching it, since that is still worth knowing. Charging starts over.
Scope {
  id: root

  // 0 none yet, 1 low, 2 critical.
  property int reached: 0

  function check() {
    if (!Battery.present) return;

    if (Battery.charging) {
      reached = 0;
      return;
    }

    const level = Battery.percent <= Settings.batteryLevels.critical ? 2 : Battery.percent <= Settings.batteryLevels.low ? 1 : 0;
    if (level <= reached) return;

    reached = level;

    if (level === 2) {
      Run.command("notify", ["--urgency=critical", "--icon=battery-empty", "Battery critical", Battery.percent + "% left. Plug in now to keep working."]);
    } else {
      Run.command("notify", ["--urgency=normal", "--icon=battery-low", "Battery low", Battery.percent + "% left."]);
    }
  }

  Component.onCompleted: check()

  Connections {
    target: Battery

    function onPresentChanged() {
      root.check();
    }

    function onPercentChanged() {
      root.check();
    }

    function onChargingChanged() {
      root.check();
    }
  }
}
