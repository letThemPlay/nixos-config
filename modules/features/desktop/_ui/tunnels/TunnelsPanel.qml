import Quickshell.Io
import QtQuick
import qs.common
import qs.services

// The network feature's tunnels under the bar's right island, like the Wi-Fi
// panel: which are up, and starting, switching or stopping them. Starting a
// tunnel stops the ones it conflicts with, so picking another full tunnel
// moves over to it.
Overlay {
  id: root

  surface: "tunnels"

  onShownChanged: {
    if (!shown) return;

    Tunnels.clearFailure();
    Tunnels.refresh();
  }

  IpcHandler {
    target: "tunnels"

    function toggle(): void {
      Ui.toggle("tunnels");
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
        height: off.implicitHeight

        Label {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "VPN"
          size: Theme.fontHeading
          font.weight: Font.DemiBold
        }

        IconButton {
          id: off

          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          opacity: Tunnels.active.length > 0 ? 1 : 0
          enabled: Tunnels.active.length > 0 && !Tunnels.busy
          icon: Tunnels.active.length > 0 ? (Tunnels.full ? "tunnelFull" : "tunnel") : "tunnelOff"
          iconSize: Theme.iconMedium
          selected: Tunnels.active.length > 0
          onClicked: Tunnels.stopAll()
        }
      }

      Label {
        width: parent.width
        visible: Tunnels.tunnels.length === 0
        topPadding: Theme.spaceMd
        bottomPadding: Theme.spaceMd
        horizontalAlignment: Text.AlignHCenter
        text: "No tunnels configured"
        color: Theme.muted
      }

      Flickable {
        id: list

        // Whatever the rest of the panel leaves, so a long list scrolls in place.
        readonly property int room: root.height - panel.y - Theme.spaceSm - Theme.spaceLg * 2 - off.implicitHeight - content.spacing

        width: parent.width
        height: Math.min(rows.implicitHeight, room)
        contentHeight: rows.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: rows

          width: list.width
          spacing: Theme.spaceXs

          Repeater {
            model: Tunnels.tunnels

            Pressable {
              id: row

              required property var modelData

              readonly property bool up: Tunnels.isUp(modelData)
              readonly property bool switching: Tunnels.isSwitching(modelData)
              readonly property bool failed: Tunnels.hasFailed(modelData)

              width: rows.width
              implicitHeight: Theme.sizeField
              passesWheel: true
              onClicked: {
                if (!up) Tunnels.toggle(modelData);
              }

              Icon {
                id: icon

                anchors.left: parent.left
                anchors.leftMargin: Theme.spaceSm
                anchors.verticalCenter: parent.verticalCenter
                name: row.modelData.routesAll ? "tunnelFull" : "tunnel"
                size: Theme.iconMedium
                color: row.up ? Theme.accent : row.foreground
              }

              Column {
                anchors.left: icon.right
                anchors.right: disconnect.left
                anchors.leftMargin: Theme.spaceMd
                anchors.rightMargin: Theme.spaceSm
                anchors.verticalCenter: parent.verticalCenter

                Label {
                  width: parent.width
                  text: row.modelData.label
                  color: row.foreground
                  font.weight: row.up ? Font.DemiBold : Font.Normal
                }

                Label {
                  width: parent.width
                  text: {
                    if (row.switching) return row.up ? "Disconnecting" : "Connecting";
                    if (row.failed) return "Couldn't switch";
                    if (row.up) return "Connected";
                    return row.modelData.routesAll ? "All traffic" : "Split";
                  }
                  size: Theme.fontSmall
                  color: row.failed && !row.switching ? Theme.danger : Theme.muted
                }
              }

              Pressable {
                id: disconnect

                anchors.right: parent.right
                anchors.rightMargin: Theme.spaceSm
                anchors.verticalCenter: parent.verticalCenter
                visible: row.up && !row.switching
                passesWheel: true
                implicitWidth: visible ? disconnectLabel.implicitWidth + Theme.spaceMd : 0
                implicitHeight: disconnectLabel.implicitHeight + Theme.spaceXs * 2
                color: Qt.alpha(Theme.outline, hovered ? 0.9 : 0.5)
                onClicked: Tunnels.toggle(row.modelData)

                Label {
                  id: disconnectLabel

                  anchors.centerIn: parent
                  text: "Disconnect"
                  size: Theme.fontSmall
                }
              }
            }
          }
        }
      }
    }
  }
}
