pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
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

  function newest(urgent) {
    const matching = Notifications.islandPopups.filter(popup => (popup.urgency === NotificationUrgency.Critical) === urgent);
    return matching[matching.length - 1] ?? null;
  }

  // A critical one waits to be acknowledged, and nothing interrupts it. An ordinary one
  // leaves on its own, and the newest replaces any before it.
  readonly property var critical: newest(true)
  readonly property var ordinary: newest(false)
  readonly property var notification: critical ?? ordinary

  // What's happening apart from a level passing through.
  readonly property string settled: {
    if (notification) return "notification";
    if (Recorder.active) return "recording";
    return Media.playing ? "media" : "clock";
  }

  readonly property string kind: {
    if (critical) return "critical";
    return Levels.shown ? "level" : settled;
  }

  // What the card opens on. Pressing during an audio level is asking about audio.
  readonly property string opening: kind === "level" && Levels.isAudio ? "audio" : settled

  // The island's own changes are bigger than a panel's, so they take a little longer.
  readonly property int motion: Theme.motionNormal * 1.5

  // The pill's width, which the card starts from as it grows out of it.
  property real compactWidth: Theme.sizeSidePanel / 2

  // A sender's own timeout wins.
  readonly property int timeout: ordinary?.expireTimeout > 0 ? ordinary.expireTimeout * 1000 : 5000

  // Those it replaces stay in the center.
  onOrdinaryChanged: {
    for (const popup of Notifications.islandPopups) {
      if (popup !== ordinary && popup.urgency !== NotificationUrgency.Critical) Qt.callLater(Notifications.hidePopup, popup);
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
    running: root.ordinary !== null && Ui.open !== "island"
    onTriggered: Notifications.hidePopup(root.ordinary)
  }
}
