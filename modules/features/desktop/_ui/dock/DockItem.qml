import QtQuick
import qs.common

// One app in the dock. The mark below its icon says it has windows open, in the
// accent colour when one of them has focus.
Pressable {
  id: root

  required property var item
  readonly property bool focused: item.windows.some(toplevel => toplevel.activated)

  signal opened
  signal closeRequested

  implicitWidth: Theme.iconLarge + Theme.spaceSm * 2
  implicitHeight: implicitWidth

  onClicked: button => {
    if (button === Qt.LeftButton) opened();
    else if (button === Qt.MiddleButton) closeRequested();
  }

  AppIcon {
    anchors.centerIn: parent
    name: root.item.icon
  }

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.spaceXs / 2
    width: Theme.spaceMd
    height: Theme.spaceXs / 2
    radius: height / 2
    color: root.focused ? Theme.accent : Theme.muted
    visible: root.item.windows.length > 0
  }
}
