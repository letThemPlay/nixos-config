import Quickshell.Wayland
import QtQuick
import qs.common

// The focused window's title.
Label {
  property real room: Theme.sizeSidePanel

  readonly property string title: ToplevelManager.activeToplevel?.title ?? ""

  readonly property bool shown: title !== ""

  text: title
  color: Theme.muted
  leftPadding: Theme.spaceSm
  rightPadding: Theme.spaceSm
  width: Math.min(implicitWidth, room)
}
