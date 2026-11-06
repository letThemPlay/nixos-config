import qs.common
import qs.notifications

// The control center's button, which also stands for the notifications in it: their
// count, and do not disturb, which a right click switches.
BarItem {
  readonly property bool hasNotifier: Settings.surfaces.includes("notifier")
  readonly property int count: hasNotifier ? Notifications.count : 0

  icon: hasNotifier && Notifications.doNotDisturb ? "notificationsPaused" : "settings"
  text: count > 0 ? String(count) : ""
  selected: Ui.open === "controlcenter"
  onClicked: button => {
    if (button === Qt.RightButton && hasNotifier)
      Notifications.doNotDisturb = !Notifications.doNotDisturb;
    else
      Ui.toggle("controlcenter");
  }
}
