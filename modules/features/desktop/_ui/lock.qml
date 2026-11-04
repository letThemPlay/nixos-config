import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.lockscreen

// The lock screen, one short-lived instance per lock. Compositors keep the
// session locked when a lock client dies, and the wrapper starts another
// (see _components/locker/quickshell.nix); it exits only after unlocking.
ShellRoot {
  LockContext {
    id: session

    onUnlocked: {
      lock.locked = false;
      Qt.quit();
    }
  }

  WlSessionLock {
    id: lock

    locked: true

    WlSessionLockSurface {
      color: "transparent"

      LockSurface {
        anchors.fill: parent
        context: session
      }
    }
  }
}
