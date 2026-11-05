import qs.common
import qs.services

// Left click opens the Bluetooth panel, or blueman on a host without one. Right
// click turns the adapter on or off.
BarItem {
  readonly property var connected: BluetoothDevices.devices.filter(device => device.connected)

  shown: BluetoothDevices.present
  selected: Ui.open === "bluetooth"
  icon: {
    if (!BluetoothDevices.enabled) return "bluetoothOff";
    return connected.length > 0 ? "bluetoothConnected" : "bluetooth";
  }
  text: connected.length === 1 ? connected[0].name : connected.length > 1 ? String(connected.length) : ""
  textWidth: Theme.sizeSidePanel / 3
  tint: connected.length > 0 && !selected ? Theme.success : foreground

  onClicked: button => {
    if (button === Qt.RightButton)
      BluetoothDevices.setEnabled(!BluetoothDevices.enabled);
    else if (Settings.surfaces.includes("bluetooth"))
      Ui.toggle("bluetooth");
    else
      Run.command("bluetoothUi");
  }
}
