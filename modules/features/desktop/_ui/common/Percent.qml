import QtQuick

// A level as text, in a column as wide as the widest it can be, so a slider
// beside it stays put and 100% never gets cut short.
Label {
  id: root

  property real level: 0

  width: widest.advanceWidth
  horizontalAlignment: Text.AlignRight
  elide: Text.ElideNone
  text: Math.round(level * 100) + "%"

  TextMetrics {
    id: widest

    font: root.font
    text: "100%"
  }
}
