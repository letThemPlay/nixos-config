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

  // The same gap above and below the islands. Only the part above is reserved:
  // the compositor already keeps its own gap between the bar and windows.
  implicitHeight: Theme.sizeBar + Theme.spaceSm * 2
  exclusiveZone: Theme.sizeBar + Theme.spaceSm
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "ltp-bar"

  readonly property var widgets: ({
    "launcher": launcher,
    "notifications": notifications,
    "workspaces": workspaces,
    "window": window,
    "tray": tray,
    "media": media,
    "network": network,
    "bluetooth": bluetooth,
    "volume": volume,
    "battery": battery,
    "clock": clock,
    "power": power
  })

  Component { id: launcher; LauncherWidget {} }
  Component { id: notifications; NotificationsWidget {} }
  Component { id: workspaces; WorkspacesWidget { screen: root.screen } }
  Component { id: window; WindowWidget {} }
  Component { id: tray; TrayWidget { window: root } }
  Component { id: media; MediaWidget {} }
  Component { id: network; NetworkWidget {} }
  Component { id: bluetooth; BluetoothWidget {} }
  Component { id: volume; VolumeWidget {} }
  Component { id: battery; BatteryWidget {} }
  Component { id: clock; ClockWidget {} }
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
    x: Theme.spaceSm
    names: Settings.barLeft
  }

  Island {
    x: root.width - width - Theme.spaceSm
    names: Settings.barRight
  }
}
