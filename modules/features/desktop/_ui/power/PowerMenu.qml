import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// The power menu. Arrows or the pointer pick an action and Enter or a click
// runs it; anything that ends the session asks a second time.
Overlay {
  id: root

  surface: "power"
  scrimmed: true

  readonly property var actions: Settings.powerActions
    .slice()
    .sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id))
  readonly property var order: ["lock", "suspend", "logout", "reboot", "poweroff"]

  property int selected: 0
  property string pending: ""

  function run(action) {
    if (action.confirm && pending !== action.id) {
      pending = action.id;
      return;
    }

    Ui.close();
    Quickshell.execDetached(action.command);
  }

  function move(step) {
    pending = "";
    selected = (selected + step + actions.length) % actions.length;
  }

  onShownChanged: {
    selected = 0;
    pending = "";
    if (shown) keys.forceActiveFocus();
  }

  IpcHandler {
    target: "power"

    function toggle(): void {
      Ui.toggle("power");
    }
  }

  Panel {
    id: panel

    anchors.centerIn: parent
    implicitWidth: row.implicitWidth + Theme.spaceMd * 2
    implicitHeight: column.implicitHeight + Theme.spaceMd * 2
    opacity: root.progress
    scale: 0.96 + root.progress * 0.04

    // Presses inside the panel must not reach the overlay's dismiss area.
    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: column

      anchors.centerIn: parent
      spacing: Theme.spaceSm

      Row {
        id: row

        spacing: Theme.spaceSm

        Repeater {
          model: root.actions

          Pressable {
            id: action

            required property var modelData
            required property int index

            readonly property bool confirming: root.pending === modelData.id

            implicitWidth: Theme.sizeField * 2
            implicitHeight: Theme.sizeField * 2
            selected: index === root.selected && !confirming
            danger: confirming

            onClicked: root.run(modelData)
            onHoveredChanged: {
              if (hovered && root.selected !== index) {
                root.pending = "";
                root.selected = index;
              }
            }

            Column {
              anchors.centerIn: parent
              spacing: Theme.spaceSm

              Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: action.modelData.icon
                size: Theme.iconLarge
                color: action.foreground
              }

              Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: action.modelData.label
                color: action.foreground
              }
            }
          }
        }
      }

      Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.pending !== "" ? "Press again to confirm" : " "
        color: Theme.danger
        size: Theme.fontSmall
      }
    }
  }

  Item {
    id: keys

    focus: true

    Keys.onPressed: event => {
      if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) root.move(-1);
      else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) root.move(1);
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.run(root.actions[root.selected]);
      else if (event.key === Qt.Key_Escape) Ui.close();
      else return;

      event.accepted = true;
    }
  }
}
