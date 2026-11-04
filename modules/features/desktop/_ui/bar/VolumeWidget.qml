import Quickshell.Services.Pipewire
import QtQuick
import qs.common

// The default output. Click mutes, scrolling changes the volume.
BarItem {
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var audio: sink?.audio ?? null
  readonly property int percent: Math.round((audio?.volume ?? 0) * 100)

  shown: audio !== null
  icon: {
    if (audio?.muted) return "volumeMuted";
    return percent >= 50 ? "volumeHigh" : "volumeLow";
  }
  text: audio?.muted ? "" : percent + "%"
  tint: audio?.muted ? Theme.warning : foreground

  onClicked: {
    if (audio) audio.muted = !audio.muted;
  }

  onScrolled: delta => {
    if (audio) audio.volume = Math.max(0, Math.min(1, audio.volume + (delta > 0 ? 0.05 : -0.05)));
  }

  PwObjectTracker {
    objects: sink ? [sink] : []
  }
}
