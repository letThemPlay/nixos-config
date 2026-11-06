import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common

// The top bar: two islands, left and right, with the desktop showing through
// between them. Which widgets each holds comes from ltp.desktop.bar.
PanelWindow {
  id: root

  anchors {
    top: true
    left: true
    right: true
  }

  // A gap above the islands, and room below for their shadows. Only the gap above is
  // reserved: the compositor already keeps its own gap between the bar and windows.
  // Only the islands take presses, so the room below never covers a window's.
  implicitHeight: Theme.sizeBar + Theme.spaceSm + Theme.shadowRoom
  exclusiveZone: Theme.sizeBar + Theme.spaceSm
  color: "transparent"

  mask: Region {
    regions: [
      Region { item: leftIsland },
      Region { item: centerIsland },
      Region { item: rightIsland }
    ]
  }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "ltp-bar"

  readonly property bool hasCenter: Settings.barCenter.length > 0

  // What the side islands leave the center one, with a gap each side.
  readonly property real centerRoom: rightIsland.x - leftIsland.x - leftIsland.width - Theme.spaceSm * 2
    - (Theme.sizeBar - Theme.sizeBarItem)

  readonly property var widgets: ({
    "island": island,
    "launcher": launcher,
    "notifications": notifications,
    "workspaces": workspaces,
    "window": window,
    "recording": recording,
    "tray": tray,
    "media": media,
    "network": network,
    "bluetooth": bluetooth,
    "volume": volume,
    "battery": battery,
    "clock": clock,
    "settings": settings,
    "power": power
  })

  // Keep awake needs a surface that stays on screen; the bar is that surface.
  IdleInhibitor {
    window: root
    enabled: Ui.keepAwake
  }

  Component { id: island; IslandWidget { room: root.centerRoom } }
  Component { id: launcher; LauncherWidget {} }
  Component { id: notifications; NotificationsWidget {} }
  Component { id: workspaces; WorkspacesWidget { screen: root.screen } }
  // The title gives way first when the center island needs the room.
  Component { id: window; WindowWidget { room: root.hasCenter ? Math.min(Theme.sizeSidePanel, root.width / 6) : Theme.sizeSidePanel } }
  Component { id: recording; RecordingWidget {} }
  Component { id: tray; TrayWidget { window: root } }
  Component { id: media; MediaWidget {} }
  Component { id: network; NetworkWidget {} }
  Component { id: bluetooth; BluetoothWidget {} }
  Component { id: volume; VolumeWidget {} }
  Component { id: battery; BatteryWidget {} }
  Component { id: clock; ClockWidget {} }
  Component { id: settings; SettingsWidget {} }
  Component { id: power; PowerWidget {} }

  component Island: Panel {
    id: island

    required property var names

    y: Theme.spaceSm
    implicitWidth: row.implicitWidth + Theme.sizeBar - Theme.sizeBarItem
    implicitHeight: Theme.sizeBar
    visible: names.length > 0

    Row {
      id: row

      anchors.centerIn: parent
      spacing: Theme.spaceXs

      Repeater {
        model: island.names

        Loader {
          required property string modelData

          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: root.widgets[modelData]

          // A widget's own shown, not visible: that one reports the parent's
          // state too, so a hidden island could never measure itself back.
          visible: item?.shown ?? true
        }
      }
    }
  }

  Island {
    id: leftIsland

    x: Theme.spaceSm
    names: Settings.barLeft
  }

  // Centered on the screen, unless the side islands leave no room for that. It hides
  // while the card is open, which grows out of it, as two translucent layers would
  // otherwise show through each other.
  Island {
    id: centerIsland

    readonly property real centered: (root.width - width) / 2
    readonly property real leftmost: leftIsland.x + leftIsland.width + Theme.spaceSm
    readonly property real rightmost: rightIsland.x - width - Theme.spaceSm

    x: Math.max(leftmost, Math.min(centered, rightmost))
    names: Settings.barCenter
    opacity: Ui.open === "island" ? 0 : 1
  }

  Island {
    id: rightIsland

    x: root.width - width - Theme.spaceSm
    names: Settings.barRight
  }
}
