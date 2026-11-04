//@ pragma UseQApplication
import Quickshell
import QtQuick
import qs.common
import qs.bar
import qs.dock
import qs.launcher
import qs.notifications
import qs.osd
import qs.polkit
import qs.power
import qs.quicksettings
import qs.services

// The unified shell. Surfaces the host did not select are never created.
// The lock screen is a separate instance (lock.qml), so restarting this one
// can never drop a lock.
ShellRoot {
  id: root

  function has(surface) {
    return Settings.surfaces.includes(surface);
  }

  // The recorder's binds reach it over IPC, and one may already be running.
  Component.onCompleted: {
    if (Recorder.available) Recorder.check();
  }

  Variants {
    model: root.has("bar") ? Quickshell.screens : []

    Bar {
      required property var modelData

      screen: modelData
    }
  }

  LazyLoader {
    active: root.has("dock")

    Dock {}
  }

  LazyLoader {
    active: root.has("launcher") || root.has("clipboard")

    Launcher {}
  }

  LazyLoader {
    active: root.has("notifier")

    Center {}
  }

  LazyLoader {
    active: root.has("notifier")

    Popups {}
  }

  LazyLoader {
    active: root.has("power")

    PowerMenu {}
  }

  LazyLoader {
    active: root.has("polkit")

    Polkit {}
  }

  LazyLoader {
    active: root.has("osd")

    Osd {}
  }

  LazyLoader {
    active: root.has("quicksettings")

    QuickSettings {}
  }

  LazyLoader {
    active: root.has("batteryAlerts")

    BatteryAlerts {}
  }
}
