pragma Singleton

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common
import qs.notifications

// What the bar's island shows: the most pressing thing happening, down to the clock.
// A lower one comes back by itself as a higher one ends.
Singleton {
  id: root

  // A fullscreen window hides the bar, and with it the island, so the level display
  // and popups go on working there rather than go unseen.
  readonly property bool fullscreen: ToplevelManager.activeToplevel?.fullscreen ?? false
  readonly property bool showing: Settings.surfaces.includes("island") && !fullscreen

  readonly property var notification: Notifications.islandPopups[Notifications.islandPopups.length - 1] ?? null

  readonly property string kind: {
    if (Levels.shown) return "level";
    if (notification) return "notification";
    if (Recorder.active) return "recording";
    return Media.playing ? "media" : "clock";
  }

  // The pill's width, which the card starts from as it grows out of it.
  property real compactWidth: Theme.sizeSidePanel / 2

  // A sender's own timeout wins.
  readonly property int timeout: notification?.expireTimeout > 0 ? notification.expireTimeout * 1000 : 5000

  // The newest replaces any before it, which stay in the center.
  onNotificationChanged: {
    for (const popup of Notifications.islandPopups) {
      if (popup !== notification) Qt.callLater(Notifications.hidePopup, popup);
    }
    leaving.restart();
  }

  Binding {
    target: Notifications
    property: "islandShowing"
    value: root.showing
  }

  // Waits while the card is open, where it's being read.
  Timer {
    id: leaving

    interval: root.timeout
    running: root.notification !== null && Ui.open !== "island"
    onTriggered: Notifications.hidePopup(root.notification)
  }
}
