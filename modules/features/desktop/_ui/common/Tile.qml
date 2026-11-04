import QtQuick

// A labelled toggle or choice: an icon above a short label.
Pressable {
  id: root

  property string icon
  property string text

  implicitHeight: Theme.sizeField + Theme.spaceSm

  Column {
    anchors.centerIn: parent
    width: parent.width - Theme.spaceSm
    spacing: Theme.spaceXs

    Icon {
      anchors.horizontalCenter: parent.horizontalCenter
      name: root.icon
      size: Theme.iconMedium
      filled: root.selected
      color: root.foreground
    }

    Label {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: root.text
      size: Theme.fontSmall
      color: root.foreground
    }
  }
}
