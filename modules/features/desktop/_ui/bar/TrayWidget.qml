import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.common

// Status notifier items, with their own menus.
Row {
  id: root

  required property var window

  readonly property bool shown: SystemTray.items.values.length > 0

  spacing: Theme.spaceXs

  Repeater {
    model: SystemTray.items

    Pressable {
      id: item

      required property SystemTrayItem modelData

      implicitWidth: implicitHeight
      implicitHeight: Theme.sizeBarItem

      onClicked: button => {
        if (button === Qt.RightButton || modelData.onlyMenu)
          menu.open();
        else if (button === Qt.MiddleButton)
          modelData.secondaryActivate();
        else
          modelData.activate();
      }

      onScrolled: delta => modelData.scroll(delta, false)

      IconImage {
        anchors.centerIn: parent
        implicitSize: Theme.iconSmall
        source: item.modelData.icon
      }

      QsMenuAnchor {
        id: menu

        menu: item.modelData.menu
        anchor.item: item
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
      }
    }
  }
}
