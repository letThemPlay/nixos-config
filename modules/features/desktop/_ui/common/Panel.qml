import QtQuick

// The one surface every component sits on.
Rectangle {
  color: Theme.panel
  radius: Theme.radiusLg
  border.width: 1
  border.color: Qt.alpha(Theme.outline, 0.5)
}
