import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.common

// The dock: a pill at the bottom edge with pinned apps, then the other apps with
// windows open. It stays out of the way of niri's columns, reserving no space and
// showing only when the pointer reaches the edge.
Scope {
  id: root

  // Shown by the IPC call, whatever the pointer does.
  property bool held: false

  // Windows by the desktop entry they belong to, so a pinned app finds its own.
  readonly property var groups: {
    const found = {};

    for (const toplevel of ToplevelManager.toplevels.values) {
      const id = DesktopEntries.heuristicLookup(toplevel.appId)?.id ?? toplevel.appId;
      found[id] = (found[id] ?? []).concat([toplevel]);
    }

    return found;
  }

  // An ID with no entry is skipped: which ones exist isn't known at evaluation.
  readonly property var pinned: {
    DesktopEntries.applications.values;

    return Settings.dockApps
      .map(id => DesktopEntries.byId(id))
      .filter(entry => entry)
      .map(entry => itemOf(entry.id, entry));
  }

  readonly property var unpinned: Object.keys(groups)
    .filter(id => !pinned.some(item => item.id === id))
    .map(id => itemOf(id, DesktopEntries.byId(id)))

  function itemOf(id, entry) {
    return {
      id: id,
      entry: entry,
      icon: entry?.icon || id,
      windows: groups[id] ?? []
    };
  }

  function launch(entry) {
    if (entry.runInTerminal) Run.inTerminal(entry.command);
    else Run.app(entry.command);
  }

  // Focuses the app, moving through its windows when it already has focus.
  function open(item) {
    const windows = item.windows;

    if (windows.length === 0) {
      if (item.entry) launch(item.entry);
      return;
    }

    const focused = windows.findIndex(toplevel => toplevel.activated);
    windows[(focused + 1) % windows.length].activate();
  }

  function closeLatest(item) {
    item.windows[item.windows.length - 1]?.close();
  }

  IpcHandler {
    target: "dock"

    function toggle(): void {
      root.held = !root.held;
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData
      readonly property bool revealed: root.held || hover.hovered || hideDelay.running

      screen: modelData

      anchors.bottom: true

      // Room for the pill's shadow, except below, where the screen's edge is.
      implicitWidth: pill.width + Theme.shadowRoom * 2
      implicitHeight: pill.height + Theme.spaceSm + Theme.shadowRoom
      exclusionMode: ExclusionMode.Ignore
      color: "transparent"
      visible: root.pinned.length + root.unpinned.length > 0

      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "ltp-dock"

      // Hidden, only the edge takes input, so it can't steal clicks from windows.
      mask: Region {
        item: window.revealed ? area : edge
      }

      Timer {
        id: hideDelay

        interval: Theme.motionNormal * 2
      }

      Item {
        id: area

        anchors.fill: parent

        HoverHandler {
          id: hover

          onHoveredChanged: {
            if (hovered) hideDelay.stop();
            else hideDelay.restart();
          }
        }

        Item {
          id: edge

          anchors.bottom: parent.bottom
          width: parent.width
          height: Theme.spaceXs
        }

        Panel {
          id: pill

          anchors.horizontalCenter: parent.horizontalCenter
          y: window.revealed ? Theme.shadowRoom : area.height
          width: row.implicitWidth + Theme.spaceSm * 2
          height: row.implicitHeight + Theme.spaceSm * 2
          opacity: window.revealed ? 1 : 0

          Behavior on y {
            NumberAnimation { duration: Theme.motionNormal; easing.type: Easing.OutCubic }
          }

          Behavior on opacity {
            NumberAnimation { duration: Theme.motionNormal }
          }

          Row {
            id: row

            anchors.centerIn: parent
            spacing: Theme.spaceXs

            Repeater {
              model: ScriptModel {
                values: root.pinned
                objectProp: "id"
              }

              DockItem {
                required property var modelData

                item: modelData
                onOpened: root.open(modelData)
                onCloseRequested: root.closeLatest(modelData)
              }
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: 1
              height: Theme.iconLarge
              color: Theme.outline
              opacity: 0.5
              visible: root.pinned.length > 0 && root.unpinned.length > 0
            }

            Repeater {
              model: ScriptModel {
                values: root.unpinned
                objectProp: "id"
              }

              DockItem {
                required property var modelData

                item: modelData
                onOpened: root.open(modelData)
                onCloseRequested: root.closeLatest(modelData)
              }
            }
          }
        }
      }
    }
  }
}
