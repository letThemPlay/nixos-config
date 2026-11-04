pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs.common

// The notification daemon: what the center lists and what is showing as a
// popup. Popups leave on their own; a notification stays in the center until
// dismissed, unless its sender marked it transient.
Singleton {
  id: root

  property bool doNotDisturb: false
  property var popups: []
  property var arrivals: ({})

  readonly property var history: [...server.trackedNotifications.values].reverse()
  readonly property int count: history.length

  function hidePopup(notification) {
    popups = popups.filter(popup => popup !== notification);
    if (notification?.transient) notification.dismiss();
  }

  function clearAll() {
    for (const notification of [...server.trackedNotifications.values])
      notification.dismiss();
  }

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

      if (!root.doNotDisturb || notification.urgency === NotificationUrgency.Critical)
        root.popups = root.popups.concat([notification]);
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
