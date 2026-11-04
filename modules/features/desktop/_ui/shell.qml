//@ pragma UseQApplication
import Quickshell
import QtQuick
import qs.common
import qs.bar
import qs.launcher
import qs.notifications
import qs.polkit
import qs.power

// The unified shell. Surfaces the host did not select are never created.
// The lock screen is a separate instance (lock.qml), so restarting this one
// can never drop a lock.
ShellRoot {
  id: root

  function has(surface) {
    return Settings.surfaces.includes(surface);
  }

  Variants {
    model: root.has("bar") ? Quickshell.screens : []

    Bar {
      required property var modelData

      screen: modelData
    }
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
}
