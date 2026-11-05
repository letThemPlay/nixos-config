pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import qs.common

// The level that just changed, for as long as it's worth showing. Volume comes from
// PipeWire, so changes from the bar or an application show too. Brightness has no
// such signal, so its keys report in over IPC.
Singleton {
  id: root

  property string icon: "volumeHigh"
  property real level: 0
  property bool warn: false
  property bool shown: false

  // The sink reports its values as it appears; those are not a change.
  property bool armed: false

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var audio: sink?.audio ?? null

  function show(newIcon, newLevel, newWarn) {
    icon = newIcon;
    level = Math.max(0, Math.min(1, newLevel));
    warn = newWarn;
    shown = true;
    hide.restart();
  }

  function showVolume() {
    if (!armed || !audio) return;

    if (audio.muted) show("volumeMuted", audio.volume, true);
    else show(audio.volume >= 0.5 ? "volumeHigh" : "volumeLow", audio.volume, false);
  }

  onSinkChanged: {
    armed = false;
    arm.restart();
  }

  Component.onCompleted: arm.restart()

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  Connections {
    target: root.audio
    ignoreUnknownSignals: true

    // The sink's last changes can arrive as the shell exits, with this already gone.
    function onVolumesChanged() {
      root?.showVolume();
    }

    function onMutedChanged() {
      root?.showVolume();
    }
  }

  Timer {
    id: arm

    interval: 1000
    onTriggered: root.armed = true
  }

  Timer {
    id: hide

    interval: 1500
    onTriggered: root.shown = false
  }

  Connections {
    target: Brightness

    function onAnnounced() {
      root.show("brightness", Brightness.level, false);
    }
  }

  IpcHandler {
    target: "osd"

    function brightness(): void {
      Brightness.refresh(true);
    }
  }
}
