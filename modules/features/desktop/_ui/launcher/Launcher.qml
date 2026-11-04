import Quickshell
import Quickshell.Io
import QtQuick
import qs.common
import "Search.js" as Search

// A centered search field that grows results as you type: applications,
// power actions and arithmetic. The clipboard opens the same surface on the
// clipboard history instead.
Scope {
  id: root

  property string mode: "launcher"
  property string query: ""
  property var clipboard: []
  property int selected: 0

  readonly property bool isOpen: Ui.open === "launcher"
  readonly property int maxResults: 7

  readonly property var results: {
    const q = query.trim().toLowerCase();

    if (mode === "clipboard") {
      return clipboard
        .filter(entry => q === "" || entry.title.toLowerCase().includes(q))
        .slice(0, maxResults);
    }

    if (q === "") return [];

    const found = [];

    const value = Search.calculate(q);
    if (value !== null) {
      found.push({
        kind: "calculator",
        score: 1000,
        title: value,
        subtitle: "Copy result",
        symbol: "calculator"
      });
    }

    if (Settings.surfaces.includes("power")) {
      for (const action of Settings.powerActions) {
        const score = Search.score(q, action.label);
        if (score > 0) {
          found.push({
            kind: "power",
            score: score - 5,
            title: action.label,
            subtitle: "System",
            symbol: action.icon,
            argv: action.command
          });
        }
      }
    }

    for (const entry of DesktopEntries.applications.values) {
      if (entry.noDisplay) continue;

      const score = Search.scoreEntry(q, entry.name, [entry.genericName, entry.comment, ...entry.keywords]);
      if (score > 0) {
        found.push({
          kind: "app",
          score: score,
          title: entry.name,
          subtitle: entry.genericName || entry.comment,
          appIcon: entry.icon,
          entry: entry
        });
      }
    }

    found.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));
    return found.slice(0, maxResults);
  }

  function show(newMode) {
    mode = newMode;
    query = "";
    selected = 0;
    Ui.open = "launcher";
    if (newMode === "clipboard") clipboardList.running = true;
  }

  function toggle(newMode) {
    if (isOpen && mode === newMode) Ui.close();
    else show(newMode);
  }

  function activate(result) {
    if (!result) return;

    if (result.kind === "app") {
      if (result.entry.runInTerminal) Run.inTerminal(result.entry.command);
      else Run.app(result.entry.command);
    } else if (result.kind === "power") {
      Quickshell.execDetached(result.argv);
    } else if (result.kind === "clipboard") {
      Quickshell.execDetached(Settings.commands.clipboardCopy.concat([result.line]));
    } else if (result.kind === "calculator") {
      Quickshell.clipboardText = result.title;
    }

    Ui.close();
  }

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      root.toggle("launcher");
    }

    function clipboard(): void {
      root.toggle("clipboard");
    }
  }

  Process {
    id: clipboardList

    command: Settings.commands.clipboardList ?? []

    stdout: StdioCollector {
      onStreamFinished: {
        root.clipboard = text.split("\n").filter(line => line !== "").map(line => ({
          kind: "clipboard",
          line: line,
          title: line.substring(line.indexOf("\t") + 1),
          subtitle: "",
          symbol: "clipboard"
        }));
      }
    }
  }

  Overlay {
    id: overlay

    surface: "launcher"

    Panel {
      id: box

      anchors.horizontalCenter: parent.horizontalCenter
      y: overlay.height * 0.22 - (1 - overlay.progress) * Theme.spaceXl
      width: Math.min(Theme.sizeLauncher, overlay.width - Theme.spaceXl * 2)
      height: column.implicitHeight
      opacity: overlay.progress
      clip: true

      // Presses inside the box must not reach the overlay's dismiss area.
      MouseArea {
        anchors.fill: parent
      }

      Column {
        id: column

        width: parent.width

        Item {
          width: parent.width
          height: Theme.sizeField

          Icon {
            id: leading

            anchors.left: parent.left
            anchors.leftMargin: Theme.spaceLg
            anchors.verticalCenter: parent.verticalCenter
            name: root.mode === "clipboard" ? "clipboard" : "search"
            size: Theme.iconMedium
            color: Theme.muted
          }

          TextInput {
            id: input

            anchors.left: leading.right
            anchors.right: parent.right
            anchors.leftMargin: Theme.spaceMd
            anchors.rightMargin: Theme.spaceLg
            anchors.verticalCenter: parent.verticalCenter

            focus: true
            text: root.query
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontHeading

            onTextEdited: {
              root.query = text;
              root.selected = 0;
            }

            Keys.onPressed: event => {
              const last = root.results.length - 1;

              if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                root.selected = root.selected >= last ? 0 : root.selected + 1;
              } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                root.selected = root.selected <= 0 ? last : root.selected - 1;
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activate(root.results[root.selected]);
              } else if (event.key === Qt.Key_Escape) {
                Ui.close();
              } else {
                return;
              }

              event.accepted = true;
            }

            Label {
              anchors.fill: parent
              visible: input.text === ""
              text: root.mode === "clipboard" ? "Search clipboard" : "Search"
              color: Theme.muted
              size: Theme.fontHeading
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Theme.outline
          opacity: 0.5
          visible: root.results.length > 0
        }

        ListView {
          id: list

          x: Theme.spaceSm
          width: parent.width - Theme.spaceSm * 2
          height: contentHeight + (count > 0 ? Theme.spaceSm * 2 : 0)
          topMargin: count > 0 ? Theme.spaceSm : 0
          interactive: false
          model: root.results
          currentIndex: root.selected

          delegate: Pressable {
            id: row

            required property var modelData
            required property int index

            width: list.width
            height: Theme.iconLarge + Theme.spaceSm * 2
            selected: index === root.selected

            onClicked: root.activate(modelData)
            onHoveredChanged: {
              if (hovered) root.selected = index;
            }

            Row {
              anchors.fill: parent
              anchors.leftMargin: Theme.spaceSm
              anchors.rightMargin: Theme.spaceSm
              spacing: Theme.spaceMd

              Loader {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconLarge
                height: Theme.iconLarge
                sourceComponent: row.modelData.kind === "app" ? appIcon : symbol
              }

              Component {
                id: appIcon

                AppIcon {
                  name: row.modelData.appIcon
                }
              }

              Component {
                id: symbol

                Icon {
                  name: row.modelData.symbol
                  color: row.foreground
                }
              }

              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Theme.iconLarge - Theme.spaceMd

                Label {
                  width: parent.width
                  text: row.modelData.title
                  size: Theme.fontTitle
                  color: row.foreground
                }

                Label {
                  width: parent.width
                  visible: text !== ""
                  text: row.modelData.subtitle ?? ""
                  size: Theme.fontSmall
                  color: row.selected ? row.foreground : Theme.muted
                }
              }
            }
          }
        }
      }
    }
  }

  Connections {
    target: Ui

    function onOpenChanged() {
      if (Ui.open === "launcher") {
        input.forceActiveFocus();
      } else {
        root.mode = "launcher";
        root.query = "";
      }
    }
  }
}
