import Quickshell
import Quickshell.WindowManager
import QtQuick
import qs.common

// This output's workspaces, through the compositor-neutral ext-workspace
// protocol. Scrolling moves between them, like the compositor's own layout.
Row {
  id: root

  required property var screen

  readonly property var workspaces: {
    const projection = screen ? WindowManager.screenProjection(screen) : null;
    const sets = projection?.windowsets ?? [];
    return sets
      .filter(set => set.shouldDisplay)
      .sort((a, b) => compare([...a.coordinates], [...b.coordinates]));
  }

  // Coordinates have several dimensions; the first that differs decides.
  function compare(a, b) {
    for (let i = 0; i < Math.max(a.length, b.length); i++) {
      const difference = (a[i] ?? 0) - (b[i] ?? 0);
      if (difference !== 0) return difference;
    }
    return 0;
  }

  function step(delta) {
    const current = workspaces.findIndex(set => set.active);
    const next = workspaces[current + (delta > 0 ? -1 : 1)];
    if (next) next.activate();
  }

  spacing: Theme.spaceXs

  Repeater {
    model: root.workspaces

    BarItem {
      required property var modelData
      required property int index

      text: modelData.name || String(index + 1)
      selected: modelData.active
      tint: {
        if (modelData.urgent) return Theme.danger;
        return foreground;
      }
      onClicked: modelData.activate()
      onScrolled: delta => root.step(delta)
    }
  }
}
