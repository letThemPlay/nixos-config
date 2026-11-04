import qs.common
import qs.notifications

// Beside the screen edge the notification center slides in from.
BarItem {
  readonly property int count: Notifications.count

  icon: {
    if (Notifications.doNotDisturb) return "notificationsPaused";
    return count > 0 ? "notificationsUnread" : "notifications";
  }
  text: count > 0 ? String(count) : ""
  selected: Ui.open === "notifications"
  onClicked: button => {
    if (button === Qt.RightButton)
      Notifications.doNotDisturb = !Notifications.doNotDisturb;
    else
      Ui.toggle("notifications");
  }
}
