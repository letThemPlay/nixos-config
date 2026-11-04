import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import qs.common
import qs.services

// A short-lived level display at the bottom of the active output. Volume comes
// from PipeWire, so changes from the bar or an application show too. Brightness
// has no such signal, so its keys report in over IPC.
Scope {
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

    function onVolumesChanged() {
      root.showVolume();
    }

    function onMutedChanged() {
      root.showVolume();
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

  PanelWindow {
    id: window

    anchors.bottom: true
    margins.bottom: Theme.spaceXl * 2

    implicitWidth: Theme.sizeSidePanel / 2 + Theme.sizeBar
    implicitHeight: Theme.sizeBar + Theme.spaceSm
    visible: root.shown || panel.opacity > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Never takes a press or a key from what is underneath.
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ltp-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Panel {
      id: panel

      anchors.fill: parent
      opacity: root.shown ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: Theme.motionNormal }
      }

      Icon {
        id: symbol

        anchors.left: parent.left
        anchors.leftMargin: Theme.spaceMd
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: Theme.iconMedium
        color: root.warn ? Theme.warning : Theme.text
      }

      Rectangle {
        id: track

        anchors.left: symbol.right
        anchors.right: percent.left
        anchors.leftMargin: Theme.spaceMd
        anchors.rightMargin: Theme.spaceMd
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.spaceXs
        radius: height / 2
        color: Qt.alpha(Theme.outline, 0.5)

        Rectangle {
          width: parent.width * root.level
          height: parent.height
          radius: parent.radius
          color: root.warn ? Theme.warning : Theme.accent

          Behavior on width {
            NumberAnimation { duration: Theme.motionFast }
          }
        }
      }

      Percent {
        id: percent

        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceMd
        anchors.verticalCenter: parent.verticalCenter
        level: root.level
      }
    }
  }
}
