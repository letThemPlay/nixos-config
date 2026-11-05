import qs.common
import qs.notifications

// The control center's button where it holds only notifications. With quick settings,
// their button stands for both.
BarItem {
  readonly property int count: Notifications.count

  icon: {
    if (Notifications.doNotDisturb) return "notificationsPaused";
    return count > 0 ? "notificationsUnread" : "notifications";
  }
  text: count > 0 ? String(count) : ""
  selected: Ui.open === "controlcenter"
  onClicked: button => {
    if (button === Qt.RightButton)
      Notifications.doNotDisturb = !Notifications.doNotDisturb;
    else
      Ui.toggle("controlcenter");
  }
}
