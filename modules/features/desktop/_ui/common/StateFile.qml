import Quickshell
import Quickshell.Io
import QtQuick

// A JSON value kept across restarts, under the shell's state directory. A missing
// or unreadable file reads as the initial value, as there's nothing to recover.
Scope {
  id: root

  required property string name
  property var value: null
  property var initial: null

  // After the file has been read, or found missing.
  signal ready

  // Deferred, as a write from within ready would cut off the read reporting it.
  function save() {
    Qt.callLater(write);
  }

  function write() {
    file.setText(JSON.stringify(value));
  }

  FileView {
    id: file

    path: Quickshell.statePath(root.name)
    printErrors: false

    onLoaded: {
      try {
        root.value = JSON.parse(text());
      } catch (error) {
        root.value = root.initial;
      }
      root.ready();
    }

    onLoadFailed: {
      root.value = root.initial;
      root.ready();
    }
  }
}
