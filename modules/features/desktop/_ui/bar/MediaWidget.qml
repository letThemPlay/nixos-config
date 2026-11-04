import Quickshell.Services.Mpris
import QtQuick
import qs.common

// The playing player, or the first one there is. Left click plays or pauses,
// right click skips.
BarItem {
  readonly property var players: Mpris.players.values
  readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null

  shown: player !== null
  icon: player?.isPlaying ? "mediaPause" : "mediaPlay"
  text: player?.trackTitle ?? ""
  textWidth: Theme.sizeSidePanel / 2

  onClicked: button => {
    if (button === Qt.RightButton)
      player?.next();
    else
      player?.togglePlaying();
  }
}
