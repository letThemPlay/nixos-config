import QtQuick

// A symbolic icon from the Icons vocabulary, in the theme's icon font.
Text {
  property string name
  property int size: Theme.iconMedium
  property bool filled: false

  text: Icons.glyph(name)
  color: Theme.text
  renderType: Text.NativeRendering

  font.family: Theme.iconFont
  font.pixelSize: size
  font.variableAxes: ({
    "FILL": filled ? 1 : 0,
    "wght": 400,
    "GRAD": 0,
    "opsz": Math.max(20, Math.min(48, size))
  })

  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter

  Behavior on color {
    ColorAnimation { duration: Theme.motionFast }
  }
}
