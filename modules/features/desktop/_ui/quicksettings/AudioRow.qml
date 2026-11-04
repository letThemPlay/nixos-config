import Quickshell.Services.Pipewire
import QtQuick
import qs.common

// One direction of audio: the default device's level, its mute, and the choice
// of device when there is more than one. Hidden where there is no device.
Column {
  id: root

  required property bool output
  required property string icon
  required property string mutedIcon

  // Volumes only update while tracked, so this holds them just while open.
  required property bool tracking

  readonly property var devices: Pipewire.nodes.values.filter(node => node.audio && !node.isStream && node.isSink === output)
  readonly property var current: output ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource
  readonly property var audio: current?.audio ?? null

  function choose(node) {
    if (output) Pipewire.preferredDefaultAudioSink = node;
    else Pipewire.preferredDefaultAudioSource = node;
  }

  visible: devices.length > 0
  spacing: Theme.spaceXs

  PwObjectTracker {
    objects: root.tracking ? root.devices : []
  }

  Row {
    width: parent.width
    spacing: Theme.spaceSm

    IconButton {
      id: mute

      anchors.verticalCenter: parent.verticalCenter
      icon: root.audio?.muted ? root.mutedIcon : root.icon
      iconSize: Theme.iconMedium
      onClicked: {
        if (root.audio) root.audio.muted = !root.audio.muted;
      }
    }

    Slider {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - mute.width - percent.width - parent.spacing * 2
      value: root.audio?.volume ?? 0
      onMoved: level => {
        if (root.audio) root.audio.volume = level;
      }
    }

    Percent {
      id: percent

      anchors.verticalCenter: parent.verticalCenter
      level: root.audio?.volume ?? 0
      color: Theme.muted
    }
  }

  Repeater {
    model: root.devices.length > 1 ? root.devices : []

    Pressable {
      required property var modelData

      width: root.width
      implicitHeight: Theme.sizeBarItem
      selected: modelData === root.current
      onClicked: root.choose(modelData)

      Label {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceMd
        anchors.rightMargin: Theme.spaceMd
        text: parent.modelData.description || parent.modelData.nickname || parent.modelData.name
        color: parent.foreground
      }
    }
  }
}
