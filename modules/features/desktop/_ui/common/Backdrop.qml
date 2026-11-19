import QtQuick
import QtQuick.Effects

// The full-screen backdrop of the lock screen and the greeter: the wallpaper
// blurred and dimmed over a solid background, so nothing shows if the
// wallpaper is missing. Children are drawn on top.
Rectangle {
  id: root

  color: Theme.background

  Image {
    id: wallpaper

    anchors.fill: parent
    visible: false
    source: Settings.wallpaper
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
  }

  MultiEffect {
    anchors.fill: parent
    source: wallpaper
    blurEnabled: true
    blur: 1
    blurMax: 64
    autoPaddingEnabled: false
    visible: wallpaper.status === Image.Ready
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.scrim
  }
}
