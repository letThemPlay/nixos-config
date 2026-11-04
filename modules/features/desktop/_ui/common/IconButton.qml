import QtQuick

// A square control holding one icon.
Pressable {
  id: root

  property string icon
  property int iconSize: Theme.iconSmall
  property bool filled: false
  property color tint: foreground

  implicitWidth: iconSize + Theme.spaceSm * 2
  implicitHeight: implicitWidth

  Icon {
    anchors.centerIn: parent
    name: root.icon
    size: root.iconSize
    filled: root.filled
    color: root.tint
  }
}
