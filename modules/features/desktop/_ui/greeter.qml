import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.greeter

// The login screen, run by greetd inside a niri of its own (see
// _adapters/greeters/quickshell.nix). Every output shows the same login,
// and one conversation with greetd behind them all. It quits once greetd
// is launching the session, and niri with it.
ShellRoot {
  GreeterContext {
    id: login
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      screen: modelData
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      WlrLayershell.namespace: "ltp-greeter"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      GreeterSurface {
        anchors.fill: parent
        greeter: login
      }
    }
  }
}
