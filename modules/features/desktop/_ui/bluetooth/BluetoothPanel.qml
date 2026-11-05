import Quickshell
import Quickshell.Io
import QtQuick
import qs.common
import qs.services

// Everyday Bluetooth under the bar's right island, beside the Wi-Fi panel's place:
// the adapter, what's nearby, pairing and connecting. Quickshell has no pairing
// agent, so a device that needs a code stays with blueman behind the link below.
Overlay {
  id: root

  surface: "bluetooth"

  // The device being paired or connected, as "pair" or "connect", and the last to
  // fail. One at a time, like the list's rows.
  property string actingAddress: ""
  property string actingKind: ""
  property string failedAddress: ""
  property string failedKind: ""

  readonly property var acting: BluetoothDevices.devices.find(device => device.address === actingAddress) ?? null

  readonly property string message: {
    if (!BluetoothDevices.present) return "No Bluetooth adapter";
    if (!BluetoothDevices.enabled) return "Bluetooth is off";
    return BluetoothDevices.devices.length === 0 ? "No devices found" : "";
  }

  function begin(device, kind) {
    actingAddress = device.address;
    actingKind = kind;
    failedAddress = "";
    failedKind = "";
  }

  function finish(failed) {
    if (failed) {
      failedAddress = actingAddress;
      failedKind = actingKind;
    }
    actingAddress = "";
    actingKind = "";
  }

  function reset() {
    actingAddress = "";
    actingKind = "";
    failedAddress = "";
    failedKind = "";
  }

  function press(device) {
    if (device.connected) return;

    if (device.pairing) {
      device.cancelPair();
      reset();
    } else if (device.paired) {
      begin(device, "connect");
      device.connect();
    } else {
      begin(device, "pair");
      device.pair();
    }
  }

  // Trusted, so it can reconnect on its own from now on.
  function paired(device) {
    device.trusted = true;
    begin(device, "connect");
    device.connect();
  }

  function iconOf(device) {
    const icon = device?.icon ?? "";

    if (icon.startsWith("audio-head")) return "deviceHeadphones";
    if (icon.startsWith("audio")) return "deviceSpeaker";
    if (icon === "input-keyboard") return "deviceKeyboard";
    if (icon === "input-mouse" || icon === "input-tablet") return "deviceMouse";
    if (icon === "input-gaming") return "deviceGamepad";
    if (icon === "phone") return "devicePhone";
    if (icon === "computer") return "deviceComputer";
    return "bluetooth";
  }

  // Scanning uses power and can disturb audio, so it's only while this is open.
  onShownChanged: {
    BluetoothDevices.setDiscovering(shown);
    if (!shown) reset();
  }

  Connections {
    target: BluetoothDevices

    function onEnabledChanged() {
      if (root.shown) BluetoothDevices.setDiscovering(BluetoothDevices.enabled);
    }
  }

  Connections {
    target: root.acting

    function onPairedChanged() {
      if (root.actingKind === "pair" && root.acting.paired) root.paired(root.acting);
    }

    function onPairingChanged() {
      if (root.actingKind === "pair" && !root.acting.pairing && !root.acting.paired) root.finish(true);
    }

    function onStateChanged() {
      if (root.actingKind !== "connect" || BluetoothDevices.changing(root.acting)) return;
      root.finish(!root.acting.connected);
    }
  }

  IpcHandler {
    target: "bluetooth"

    function toggle(): void {
      Ui.toggle("bluetooth");
    }
  }

  Panel {
    id: panel

    x: root.width - width - Theme.spaceSm
    y: Theme.sizeBar + Theme.spaceSm * 2 - (1 - root.progress) * Theme.spaceXl
    width: Theme.sizeSidePanel
    height: Math.min(content.implicitHeight + Theme.spaceLg * 2, root.height - y - Theme.spaceSm)
    opacity: root.progress

    // Presses inside the panel must not reach the overlay's dismiss area.
    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: content

      x: Theme.spaceLg
      y: Theme.spaceLg
      width: parent.width - Theme.spaceLg * 2
      spacing: Theme.spaceSm

      Item {
        width: parent.width
        height: power.implicitHeight

        Label {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Bluetooth"
          size: Theme.fontHeading
          font.weight: Font.DemiBold
        }

        Label {
          anchors.right: power.left
          anchors.rightMargin: Theme.spaceSm
          anchors.verticalCenter: parent.verticalCenter
          visible: BluetoothDevices.discovering
          text: "Scanning"
          size: Theme.fontSmall
          color: Theme.muted
        }

        IconButton {
          id: power

          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: BluetoothDevices.present
          icon: BluetoothDevices.enabled ? "bluetooth" : "bluetoothOff"
          iconSize: Theme.iconMedium
          selected: BluetoothDevices.enabled
          onClicked: BluetoothDevices.setEnabled(!BluetoothDevices.enabled)
        }
      }

      Label {
        width: parent.width
        visible: root.message !== ""
        topPadding: Theme.spaceMd
        bottomPadding: Theme.spaceMd
        horizontalAlignment: Text.AlignHCenter
        text: root.message
        color: Theme.muted
      }

      Flickable {
        id: list

        // Whatever the rest of the panel leaves, so a long list scrolls in place.
        readonly property int room: root.height - panel.y - Theme.spaceSm - Theme.spaceLg * 2
          - power.implicitHeight - footer.height - content.spacing * 2

        width: parent.width
        height: Math.min(rows.implicitHeight, room)
        contentHeight: rows.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: root.message === ""

        Column {
          id: rows

          width: list.width
          spacing: Theme.spaceXs

          Repeater {
            // Addresses, so a row outlives each change to the list; its values are
            // looked up, as a kept row's model data isn't refreshed.
            model: ScriptModel {
              values: BluetoothDevices.devices.map(device => device.address)
            }

            Pressable {
              id: row

              required property string modelData

              readonly property var device: BluetoothDevices.devices.find(device => device.address === modelData) ?? null
              readonly property bool connected: device?.connected ?? false
              readonly property bool paired: device?.paired ?? false

              width: rows.width
              implicitHeight: Theme.sizeField
              passesWheel: true
              onClicked: {
                if (device) root.press(device);
              }

              HoverHandler {
                id: rowHover
              }

              Icon {
                id: kind

                anchors.left: parent.left
                anchors.leftMargin: Theme.spaceSm
                anchors.verticalCenter: parent.verticalCenter
                name: root.iconOf(row.device)
                size: Theme.iconMedium
                color: row.connected ? Theme.accent : row.foreground
              }

              Column {
                anchors.left: kind.right
                anchors.right: actions.left
                anchors.leftMargin: Theme.spaceMd
                anchors.rightMargin: Theme.spaceSm
                anchors.verticalCenter: parent.verticalCenter

                Label {
                  width: parent.width
                  text: row.device?.name ?? ""
                  color: row.foreground
                  font.weight: row.connected ? Font.DemiBold : Font.Normal
                }

                Label {
                  readonly property bool failed: root.failedAddress === row.modelData

                  width: parent.width
                  visible: text !== ""
                  text: {
                    if (row.device?.pairing) return "Pairing";
                    if (row.connected) {
                      if (!row.device.batteryAvailable) return "Connected";
                      return "Connected · " + Math.round(row.device.battery * 100) + "%";
                    }
                    if (BluetoothDevices.connecting(row.device) || root.actingAddress === row.modelData) return "Connecting";
                    if (failed) return root.failedKind === "pair" ? "Couldn't pair" : "Couldn't connect";
                    return row.paired ? "Paired" : "";
                  }
                  size: Theme.fontSmall
                  color: failed && root.actingAddress !== row.modelData ? Theme.danger : Theme.muted
                }
              }

              Row {
                id: actions

                anchors.right: parent.right
                anchors.rightMargin: Theme.spaceSm
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spaceXs

                component Action: Pressable {
                  id: action

                  property string text

                  passesWheel: true
                  implicitWidth: actionLabel.implicitWidth + Theme.spaceMd
                  implicitHeight: actionLabel.implicitHeight + Theme.spaceXs * 2
                  color: Qt.alpha(Theme.outline, hovered ? 0.9 : 0.5)

                  Label {
                    id: actionLabel

                    anchors.centerIn: parent
                    text: action.text
                    size: Theme.fontSmall
                  }
                }

                Action {
                  visible: rowHover.hovered && row.paired
                  text: "Forget"
                  onClicked: row.device.forget()
                }

                Action {
                  visible: row.connected
                  text: "Disconnect"
                  onClicked: row.device.disconnect()
                }
              }
            }
          }
        }
      }

      Pressable {
        id: footer

        width: parent.width
        implicitHeight: Theme.sizeBarItem + Theme.spaceSm
        visible: Run.has("bluetoothUi")
        onClicked: {
          Ui.close();
          Run.command("bluetoothUi");
        }

        Label {
          anchors.left: parent.left
          anchors.right: footerMore.left
          anchors.leftMargin: Theme.spaceSm
          anchors.verticalCenter: parent.verticalCenter
          text: "More settings"
          color: parent.foreground
        }

        Icon {
          id: footerMore

          anchors.right: parent.right
          anchors.rightMargin: Theme.spaceSm
          anchors.verticalCenter: parent.verticalCenter
          name: "more"
          size: Theme.iconSmall
          color: Theme.muted
        }
      }
    }
  }
}
