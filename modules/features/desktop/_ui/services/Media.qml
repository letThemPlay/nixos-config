pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The playing player, or the first one there is.
Singleton {
  readonly property var players: Mpris.players.values
  readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
  readonly property bool playing: player?.isPlaying ?? false
}
