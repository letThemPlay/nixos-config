import QtQuick

// Every line of interface text, in the theme's type scale.
Text {
  property int size: Theme.fontBody

  color: Theme.text
  elide: Text.ElideRight
  renderType: Text.NativeRendering
  textFormat: Text.PlainText
  verticalAlignment: Text.AlignVCenter

  font.family: Theme.fontFamily
  font.pointSize: size
}
