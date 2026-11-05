pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import qs.common

// The level that just changed, for as long as it's worth showing. Volume comes from
// PipeWire, so changes from the bar or an application show too, and the microphone's
// likewise. Brightness has no such signal, so its keys report in over IPC.
Singleton {
  id: root

  property string icon: "volumeHigh"
  property real level: 0
  property bool warn: false
  property bool shown: false

  // Which one: "output", "input" or "brightness".
  property string source: "output"

  // The device, where that's worth saying.
  property string label: ""

  // A new output was chosen, so its name is the news rather than its level.
  property bool deviceOnly: false

  // A device reports its values as it appears; those are not a change.
  property bool armed: false

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var audio: sink?.audio ?? null
  readonly property var microphone: Pipewire.defaultAudioSource
  readonly property var microphoneAudio: microphone?.audio ?? null

  readonly property bool isAudio: source === "output" || source === "input"

  // The charger's state as UPower first answers isn't a change either.
  property bool chargerArmed: false

  function nameOf(node) {
    return node?.description || node?.nickname || node?.name || "";
  }

  function show(newSource, newIcon, newLevel, newWarn, newLabel, duration) {
    source = newSource;
    icon = newIcon;
    level = Math.max(0, Math.min(1, newLevel));
    warn = newWarn;
    label = newLabel;
    deviceOnly = false;
    shown = true;
    hide.interval = duration ?? 1500;
    hide.restart();
  }

  function chargerLabel() {
    if (Battery.charging) return "Charging";

    // UPower takes a moment to estimate after unplugging.
    const minutes = Math.round(Battery.timeToEmpty / 60);
    if (minutes <= 0) return "On battery";

    const hours = Math.floor(minutes / 60);
    return (hours > 0 ? hours + " h " : "") + minutes % 60 + " min left";
  }

  // Only with the island, as this is news it has room for. Other layouts stay as they were.
  function showCharger() {
    if (!chargerArmed || !Battery.present || !Settings.surfaces.includes("island")) return;

    show("battery", Battery.icon, Battery.percent / 100, false, chargerLabel(), 3000);
  }

  function showVolume() {
    if (!armed || !audio) return;

    if (audio.muted) show("output", "volumeMuted", audio.volume, true, "");
    else show("output", audio.volume >= 0.5 ? "volumeHigh" : "volumeLow", audio.volume, false, "");
  }

  function showMicrophone() {
    if (!armed || !microphoneAudio) return;

    const muted = microphoneAudio.muted;
    show("input", muted ? "microphoneMuted" : "microphone", microphoneAudio.volume, muted, nameOf(microphone));
  }

  function showDevice() {
    show("output", "volumeHigh", audio?.volume ?? 0, false, nameOf(sink));
    deviceOnly = true;
  }

  // A device going away briefly on its way to another is not a change to announce, and
  // the first one at startup isn't news.
  onSinkChanged: {
    if (sink === null) return;

    const announce = armed;
    armed = false;
    arm.restart();
    if (announce) showDevice();
  }

  onMicrophoneChanged: {
    armed = false;
    arm.restart();
  }

  Component.onCompleted: arm.restart()

  PwObjectTracker {
    objects: [root.sink, root.microphone].filter(node => node)
  }

  // Their last changes can arrive as the shell exits, with this already gone.
  Connections {
    target: root.audio
    ignoreUnknownSignals: true

    function onVolumesChanged() {
      root?.showVolume();
    }

    function onMutedChanged() {
      root?.showVolume();
    }
  }

  Connections {
    target: root.microphoneAudio
    ignoreUnknownSignals: true

    function onVolumesChanged() {
      root?.showMicrophone();
    }

    function onMutedChanged() {
      root?.showMicrophone();
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

  Timer {
    interval: 1000
    running: Battery.present
    onTriggered: root.chargerArmed = true
  }

  Connections {
    target: Battery

    function onChargingChanged() {
      root.showCharger();
    }
  }

  Connections {
    target: Brightness

    function onAnnounced() {
      root.show("brightness", "brightness", Brightness.level, false, "");
    }
  }

  IpcHandler {
    target: "osd"

    function brightness(): void {
      Brightness.refresh(true);
    }
  }
}
