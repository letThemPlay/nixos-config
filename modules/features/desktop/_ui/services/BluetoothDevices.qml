pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// The adapter and what it can see. The only file that reaches BlueZ, so a test can
// replace this one and be sure of leaving the real adapter alone.
Singleton {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter

  readonly property bool present: adapter !== null
  readonly property bool enabled: adapter?.enabled ?? false
  readonly property bool discovering: adapter?.discovering ?? false

  // Most of what's nearby and unnamed is noise, such as other people's devices.
  readonly property var devices: (adapter?.devices.values ?? [])
    .filter(device => device.connected || device.paired || device.deviceName !== "")
    .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

  function setEnabled(on) {
    if (adapter) adapter.enabled = on;
  }

  function setDiscovering(on) {
    if (adapter?.enabled) adapter.discovering = on;
  }

  function connecting(device) {
    return device?.state === BluetoothDeviceState.Connecting;
  }

  // Still on its way somewhere, so not yet a failure.
  function changing(device) {
    return connecting(device) || device?.state === BluetoothDeviceState.Disconnecting;
  }
}
