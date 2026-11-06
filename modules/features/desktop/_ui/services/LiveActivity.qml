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
    return Media.playing ? "media" : "idle";
  }

  readonly property string kind: {
    if (critical) return "critical";
    return Levels.shown ? "level" : settled;
  }

  // How the island is presented, which is separate from everything above: nothing here
  // changes what's active. Collapsed is the card not being open. Expanded shows what's
  // active alongside the system overview. Focused shows one thing with its fuller
  // controls: media, notification, month or audio.
  property string presentation: "expanded"
  property string focusedOn: ""

  // Opened straight into focus, so there's nothing to go back to.
  property bool focusedDirectly: false

  readonly property bool isFocused: presentation === "focused"
  readonly property bool readingNotification: Ui.open === "island" && isFocused && focusedOn === "notification"

  function expand() {
    presentation = "expanded";
    focusedOn = "";
    focusedDirectly = false;
    Ui.open = "island";
  }

  function focusOn(what, directly) {
    presentation = "focused";
    focusedOn = what;
    focusedDirectly = directly;
    Ui.open = "island";
  }

  function collapse() {
    Ui.close();
  }

  // Pressing during an audio level is asking about audio.
  function press() {
    if (Ui.open === "island") collapse();
    else if (kind === "level" && Levels.isAudio) focusOn("audio", true);
    else expand();
  }

  // Which focused view answers for what's going on. Recording has none, as its Stop is
  // already in the expanded card, so it's only passed over for a track. A paused track
  // is what's left to come back to, ahead of the month.
  function currentFocus() {
    if (critical) return "notification";
    if (kind === "level" && Levels.isAudio) return "audio";
    if (notification) return "notification";
    if (Media.playing) return "media";
    if (Recorder.active) return "";
    return Media.player ? "media" : "month";
  }

  function focusCurrent() {
    const what = currentFocus();

    if (what) focusOn(what, true);
    else expand();
  }

  // The island's own changes are bigger than a panel's, so they take a little longer.
  readonly property int motion: Theme.motionNormal * 1.5

  // The pill's width, which the card starts from as it grows out of it.
  property real compactWidth: Theme.sizeSidePanel / 2

  // A sender's own timeout wins.
  readonly property int timeout: ordinary?.expireTimeout > 0 ? ordinary.expireTimeout : 5000

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

  // The idle pill shows CPU and memory, so they're read while it can be seen. Here
  // rather than in the pill, as there's one on every screen.
  Binding {
    target: SystemLoad
    property: "watchingPill"
    value: root.showing && root.kind === "idle" && Ui.open !== "island"
  }

  // Waits only while focused, where it's being read.
  Timer {
    id: leaving

    interval: root.timeout
    running: root.ordinary !== null && !root.readingNotification
    onTriggered: Notifications.hidePopup(root.ordinary)
  }
}
