import Quickshell.Bluetooth
import qs.common

// Left click opens the bluetooth UI, right click turns the adapter on or off.
BarItem {
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var connected: (adapter?.devices.values ?? []).filter(device => device.connected)

  shown: adapter !== null
  icon: {
    if (!adapter?.enabled) return "bluetoothOff";
    return connected.length > 0 ? "bluetoothConnected" : "bluetooth";
  }
  text: connected.length === 1 ? connected[0].name : connected.length > 1 ? String(connected.length) : ""
  textWidth: Theme.sizeSidePanel / 3
  tint: connected.length > 0 ? Theme.success : foreground

  onClicked: button => {
    if (button === Qt.RightButton && adapter)
      adapter.enabled = !adapter.enabled;
    else
      Run.command("bluetoothUi");
  }
}
