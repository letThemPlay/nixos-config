import QtQuick
import qs.common

// One entry of the bar: an icon, optional text and the shared states. Every
// widget is one of these, so they all measure and behave alike.
Pressable {
  id: root

  property bool shown: true
  property string icon
  property string text
  property color tint: foreground
  property bool filled: false
  property int textWidth: 0

  implicitHeight: Theme.sizeBarItem
  // At least square, so a single digit or icon does not make a sliver.
  implicitWidth: Math.max(implicitHeight, content.implicitWidth + Theme.spaceSm * 2)

  Row {
    id: content

    anchors.centerIn: parent
    spacing: Theme.spaceXs

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== ""
      name: root.icon
      size: Theme.iconSmall
      filled: root.filled
      color: root.tint
    }

    Label {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.text !== ""
      text: root.text
      color: root.tint
      width: root.textWidth > 0 ? Math.min(implicitWidth, root.textWidth) : implicitWidth
    }
  }
}
