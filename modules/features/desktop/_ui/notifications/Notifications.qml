pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs.common

// The notification daemon: what the center lists and what is showing as a
// popup. Popups leave on their own; a notification stays in the center until
// dismissed, unless its sender marked it transient. What's in the center is also
// saved, and comes back after a restart as a plain record with no actions, since
// the sender is no longer listening for them.
Singleton {
  id: root

  property bool doNotDisturb: false
  property var popups: []
  property var arrivals: ({})

  readonly property var history: [...server.trackedNotifications.values].reverse()
  readonly property int count: history.length

  // Records from before this run, newest first, in the shape a card reads.
  readonly property var earlier: (saved.value ?? [])
    .filter(record => record.session !== run.session)
    .reverse()
    .map(record => Object.assign({}, record, {
      actions: [],
      dismiss: () => root.forget(record)
    }))

  function hidePopup(notification) {
    popups = popups.filter(popup => popup !== notification);
    if (notification?.transient) notification.dismiss();
  }

  function clearAll() {
    for (const notification of [...server.trackedNotifications.values])
      notification.dismiss();
    store([]);
  }

  function forget(record) {
    store(saved.value.filter(kept => kept.session !== record.session || kept.id !== record.id));
  }

  // Writes only on a change, so a limit of 0 never creates the file.
  function store(records) {
    const limit = Settings.notificationHistory.limit;
    const oldest = Date.now() - Settings.notificationHistory.days * 86400000;
    const recent = records.filter(record => record.time >= oldest);
    const kept = limit > 0 ? recent.slice(-limit) : [];

    if (JSON.stringify(kept) === JSON.stringify(saved.value)) return;
    saved.value = kept;
    saved.save();
  }

  // Sent images are left out, as their temp files won't last.
  function recordOf(notification) {
    const known = saved.value.find(record => record.session === run.session && record.id === notification.id);

    return {
      session: run.session,
      id: notification.id,
      appName: notification.appName,
      appIcon: notification.appIcon || notification.desktopEntry,
      summary: notification.summary,
      body: notification.body,
      urgency: notification.urgency,
      time: known?.time ?? Date.now()
    };
  }

  // Earlier records plus what's live now, so a dismissal drops its record and a
  // config reload, which keeps both, changes nothing.
  function sync() {
    if (!saved.value) return;

    const before = saved.value.filter(record => record.session !== run.session);
    const live = server.trackedNotifications.values.filter(notification => !notification.transient);
    store(before.concat(live.map(recordOf)));
  }

  onHistoryChanged: sync()

  function dismissLatest() {
    (popups[popups.length - 1] ?? history[0])?.dismiss();
  }

  function arrival(notification) {
    return arrivals[notification.id] ?? new Date();
  }

  NotificationServer {
    id: server

    keepOnReload: true
    actionsSupported: true
    imageSupported: true
    bodySupported: true
    persistenceSupported: true

    onNotification: notification => {
      notification.tracked = true;
      root.arrivals[notification.id] = new Date();

      notification.closed.connect(() => {
        root.popups = root.popups.filter(popup => popup !== notification);
      });

      // A sender can replace the text of one it already sent.
      notification.summaryChanged.connect(root.sync);
      notification.bodyChanged.connect(root.sync);

      if (!root.doNotDisturb || notification.urgency === NotificationUrgency.Critical)
        root.popups = root.popups.concat([notification]);
    }
  }

  // One run's ID, kept across config reloads, which keep its notifications too.
  PersistentProperties {
    id: run

    reloadableId: "notifications"

    property string session: ""

    onLoaded: {
      if (session === "") session = String(Date.now());
    }
  }

  StateFile {
    id: saved

    name: "notifications.json"
    initial: []

    onReady: {
      root.store(value);
      root.sync();
    }
  }

  // Opening the center shows everything the popups were showing.
  Connections {
    target: Ui

    function onOpenChanged() {
      if (Ui.open !== "notifications") return;

      for (const popup of root.popups)
        root.hidePopup(popup);
    }
  }

  IpcHandler {
    target: "notifications"

    function toggle(): void {
      Ui.toggle("notifications");
    }

    function dismiss(): void {
      root.dismissLatest();
    }

    function clear(): void {
      root.clearAll();
    }

    function toggleDoNotDisturb(): void {
      root.doNotDisturb = !root.doNotDisturb;
    }
  }
}
