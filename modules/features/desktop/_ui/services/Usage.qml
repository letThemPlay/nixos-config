pragma Singleton

import Quickshell
import QtQuick
import qs.common

// Which applications get launched, for ranking search results. It holds desktop
// IDs only, never what was typed.
Singleton {
  id: root

  readonly property var apps: state.value ?? {}

  function record(id) {
    const next = Object.assign({}, apps);
    next[id] = {
      count: (apps[id]?.count ?? 0) + 1,
      last: Date.now()
    };
    state.value = next;
    state.save();
  }

  StateFile {
    id: state

    name: "launcher-usage.json"
    initial: ({})
  }
}
