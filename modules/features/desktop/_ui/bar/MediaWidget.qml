import QtQuick
import qs.common
import qs.services

// Left click plays or pauses, right click skips.
BarItem {
  readonly property var player: Media.player

  shown: player !== null
  icon: Media.playing ? "mediaPause" : "mediaPlay"
  text: player?.trackTitle ?? ""
  textWidth: Theme.sizeSidePanel / 2

  onClicked: button => {
    if (button === Qt.RightButton)
      player?.next();
    else
      player?.togglePlaying();
  }
}
