import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common

// Popups on the left under the bar: the edge the center opens from, so a popup
// reads as the center's newest entry arriving, and clear of where niri's new
// columns scroll into view.
PanelWindow {
  id: root

  anchors {
    top: true
    left: true
  }

  // Room for the cards' shadows, except along the screen edge, where it would only fall
  // off screen. Only the cards take presses.
  margins.top: Theme.sizeBar + Theme.spaceSm * 2 - Theme.shadowRoom

  visible: Notifications.cardPopups.length > 0
  implicitWidth: Theme.spaceSm + Theme.sizeSidePanel + Theme.shadowRoom
  implicitHeight: Math.max(1, stack.implicitHeight + Theme.shadowRoom * 2)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  mask: Region {
    item: stack
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "ltp-notification-popups"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Column {
    id: stack

    x: Theme.spaceSm
    y: Theme.shadowRoom
    width: Theme.sizeSidePanel
    spacing: Theme.spaceSm

    Repeater {
      model: ScriptModel {
        values: Notifications.cardPopups
      }

      NotificationCard {
        id: card

        required property var modelData

        // A sender's own timeout wins; critical notifications wait for the user.
        readonly property int timeout: {
          if (critical) return 0;
          return modelData?.expireTimeout > 0 ? modelData.expireTimeout : 5000;
        }
        readonly property real hiddenX: -width - Theme.spaceSm

        property real slide: hiddenX

        notification: modelData
        width: stack.width

        transform: Translate {
          x: card.slide
        }

        NumberAnimation {
          running: true
          target: card
          property: "slide"
          to: 0
          duration: Theme.motionNormal
          easing.type: Easing.OutCubic
        }

        NumberAnimation {
          id: leaving

          target: card
          property: "slide"
          to: card.hiddenX
          duration: Theme.motionNormal
          easing.type: Easing.InCubic
          onFinished: Notifications.hidePopup(card.modelData)
        }

        Timer {
          interval: card.timeout
          running: interval > 0 && !card.hovered && !leaving.running
          onTriggered: leaving.start()
        }
      }
    }
  }
}
