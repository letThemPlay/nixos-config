import QtQuick
import QtQuick.Effects

// The one surface every component sits on. It casts a soft shadow, so it lifts off
// whatever is behind it; one inside another panel turns that off, as it's already
// raised. A window sized to its content leaves Theme.shadowRoom around it.
Rectangle {
  id: root

  property bool elevated: true

  color: Theme.panel
  radius: Theme.radiusLg
  border.width: 1
  border.color: Qt.alpha(Theme.outline, 0.5)

  RectangularShadow {
    anchors.fill: parent
    z: -1
    visible: root.elevated
    radius: root.radius
    blur: Theme.shadowBlur
    offset.y: Theme.shadowOffset
    color: Theme.shadow
  }
}
