pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Whether anything is capturing from a microphone, and what. Every source is watched, as
// an app can use one other than the default. The visualizer listens to the output's
// monitor, which belongs to the sink, so it doesn't count.
Singleton {
  id: root

  readonly property var sources: Pipewire.nodes.values.filter(node => node.audio && !node.isStream && !node.isSink)
  readonly property var groups: [...trackers.instances].reduce((all, tracker) => all.concat([...tracker.linkGroups]), [])

  readonly property bool active: groups.length > 0

  // Still connected, but hearing nothing.
  readonly property bool muted: Pipewire.defaultAudioSource?.audio?.muted ?? false

  readonly property string users: [...new Set(groups.map(group => Levels.nameOf(group.target)).filter(name => name !== ""))].join(", ")

  PwObjectTracker {
    objects: root.sources
  }

  Variants {
    id: trackers

    model: root.sources

    PwNodeLinkTracker {
      required property var modelData

      node: modelData
    }
  }
}
