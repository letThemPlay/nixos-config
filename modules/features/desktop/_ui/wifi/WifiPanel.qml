import Quickshell
import Quickshell.Io
import QtQuick
import qs.common
import qs.services

// Everyday Wi-Fi under the bar's right island: the radio, what's in range, joining
// and forgetting. Enterprise and hidden networks need far more than this, so they
// stay in the backend's own window behind the link at the bottom.
Overlay {
  id: root

  surface: "wifi"

  // The network whose passphrase is being asked for.
  property string asking: ""

  readonly property string message: {
    if (Wifi.problem === "not-allowed") return "Your user can't manage Wi-Fi";
    if (Wifi.problem !== "") return "Wi-Fi isn't available";
    if (!Wifi.present) return "No Wi-Fi adapter";
    if (!Wifi.powered) return "Wi-Fi is off";
    return Wifi.networks.length === 0 ? "No networks found" : "";
  }

  function canJoin(network) {
    return network.security === "open" || network.security === "psk";
  }

  function press(network) {
    if (network.connected || !canJoin(network)) return;

    if (network.security === "open" || network.known) {
      asking = "";
      Wifi.join(network.path, "");
    } else {
      asking = asking === network.path ? "" : network.path;
    }
  }

  onShownChanged: {
    Wifi.watching = shown;
    Wifi.clearFailure();
    asking = "";
  }

  Connections {
    target: Wifi

    function onJoinFailed(path, code) {
      if (code === "wrong-passphrase" || code === "needs-passphrase") root.asking = path;
    }
  }

  IpcHandler {
    target: "wifi"

    function toggle(): void {
      Ui.toggle("wifi");
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
          text: "Wi-Fi"
          size: Theme.fontHeading
          font.weight: Font.DemiBold
        }

        Label {
          anchors.right: power.left
          anchors.rightMargin: Theme.spaceSm
          anchors.verticalCenter: parent.verticalCenter
          visible: Wifi.scanning
          text: "Scanning"
          size: Theme.fontSmall
          color: Theme.muted
        }

        IconButton {
          id: power

          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: Wifi.present
          icon: Wifi.powered ? "wifiFull" : "wifiOff"
          iconSize: Theme.iconMedium
          selected: Wifi.powered
          onClicked: Wifi.act(["power", Wifi.powered ? "off" : "on"])
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
            // Paths, so a row and what's typed in it outlive each poll; its values
            // are looked up, as a kept row's model data isn't refreshed.
            model: ScriptModel {
              values: Wifi.networks.map(network => network.path)
            }

            Column {
              id: entry

              required property string modelData

              readonly property var network: Wifi.networks.find(network => network.path === modelData) ?? ({})
              readonly property bool connected: network.connected ?? false
              readonly property bool joining: Wifi.joining === modelData
              readonly property bool asked: root.asking === modelData
              readonly property bool joinable: root.canJoin(network)
              readonly property bool failed: Wifi.failedPath === modelData

              width: rows.width
              spacing: Theme.spaceXs

              onAskedChanged: {
                if (asked) field.takeFocus();
                else field.text = "";
              }

              onConnectedChanged: {
                if (connected && asked) root.asking = "";
              }

              Pressable {
                id: row

                width: parent.width
                implicitHeight: Theme.sizeField
                opacity: entry.joinable ? 1 : 0.6
                passesWheel: true
                onClicked: root.press(entry.network)

                HoverHandler {
                  id: rowHover
                }

                Icon {
                  id: signal

                  anchors.left: parent.left
                  anchors.leftMargin: Theme.spaceSm
                  anchors.verticalCenter: parent.verticalCenter
                  name: {
                    if (entry.network.signal >= 66) return "wifiFull";
                    return entry.network.signal >= 33 ? "wifiMedium" : "wifiLow";
                  }
                  size: Theme.iconMedium
                  color: entry.network.connected ? Theme.accent : row.foreground
                }

                Column {
                  anchors.left: signal.right
                  anchors.right: actions.left
                  anchors.leftMargin: Theme.spaceMd
                  anchors.rightMargin: Theme.spaceSm
                  anchors.verticalCenter: parent.verticalCenter

                  Label {
                    width: parent.width
                    text: entry.network.name ?? ""
                    color: row.foreground
                    font.weight: entry.network.connected ? Font.DemiBold : Font.Normal
                  }

                  Label {
                    width: parent.width
                    visible: text !== ""
                    text: {
                      if (entry.joining) return "Connecting";
                      if (entry.network.connected) return "Connected";
                      if (!entry.joinable) return "Use More settings";
                      if (entry.failed && !entry.asked) return "Couldn't connect";
                      return entry.network.known ? "Saved" : "";
                    }
                    size: Theme.fontSmall
                    color: entry.failed && !entry.asked && !entry.joining ? Theme.danger : Theme.muted
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
                    visible: rowHover.hovered && entry.network.known
                    text: "Forget"
                    onClicked: Wifi.act(["forget", entry.modelData])
                  }

                  Action {
                    visible: entry.network.connected
                    text: "Disconnect"
                    onClicked: Wifi.act(["disconnect"])
                  }

                  Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.network.security !== "open"
                    name: "lock"
                    size: Theme.iconSmall
                    color: Theme.muted
                  }
                }
              }

              Column {
                width: parent.width
                spacing: Theme.spaceXs
                visible: entry.asked

                PasswordField {
                  id: field

                  width: parent.width
                  busy: entry.joining
                  failed: entry.failed && Wifi.failedCode === "wrong-passphrase"

                  onEdited: Wifi.clearFailure()
                  onAccepted: {
                    Wifi.join(entry.modelData, text);
                    text = "";
                  }

                  Connections {
                    target: Wifi

                    function onJoinFailed(path, code) {
                      if (path !== entry.modelData) return;

                      field.takeFocus();
                      if (code === "wrong-passphrase") field.shake();
                    }
                  }
                }

                Label {
                  leftPadding: Theme.spaceSm
                  visible: field.failed
                  text: "Wrong password"
                  size: Theme.fontSmall
                  color: Theme.danger
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
        visible: Run.has("networkUi")
        onClicked: {
          Ui.close();
          Run.command("networkUi");
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
