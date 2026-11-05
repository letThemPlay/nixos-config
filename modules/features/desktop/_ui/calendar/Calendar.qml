import Quickshell
import Quickshell.Io
import QtQuick
import qs.common
import "Month.js" as Month

// A month view under the bar's clock, always opening on the current month. It only
// shows dates: there are no events to keep or accounts to reach.
Overlay {
  id: root

  surface: "calendar"

  property int year: 0
  property int month: 0

  // Touchpads scroll in many small steps, so a month takes a full wheel notch.
  property int scrollTotal: 0

  readonly property var locale: Qt.locale()
  readonly property int cell: Theme.sizeBarItem + Theme.spaceXs
  readonly property var days: Month.days(year, month, locale.firstDayOfWeek)
  readonly property string today: clock.date.toDateString()

  function showCurrent() {
    const now = new Date();
    year = now.getFullYear();
    month = now.getMonth();
  }

  function move(months) {
    const first = new Date(year, month + months, 1);
    year = first.getFullYear();
    month = first.getMonth();
  }

  function scroll(delta) {
    scrollTotal += delta;
    if (Math.abs(scrollTotal) < 120) return;

    move(scrollTotal > 0 ? -1 : 1);
    scrollTotal = 0;
  }

  onShownChanged: {
    if (shown) showCurrent();
  }

  Component.onCompleted: showCurrent()

  SystemClock {
    id: clock

    precision: SystemClock.Hours
  }

  IpcHandler {
    target: "calendar"

    function toggle(): void {
      Ui.toggle("calendar");
    }
  }

  Panel {
    id: panel

    x: root.width - width - Theme.spaceSm
    y: Theme.sizeBar + Theme.spaceSm * 2 - (1 - root.progress) * Theme.spaceXl
    width: content.implicitWidth + Theme.spaceLg * 2
    height: content.implicitHeight + Theme.spaceLg * 2
    opacity: root.progress
    focus: true

    Keys.onLeftPressed: root.move(-1)
    Keys.onRightPressed: root.move(1)

    // Presses inside the panel must not reach the overlay's dismiss area.
    MouseArea {
      anchors.fill: parent
      onWheel: event => root.scroll(event.angleDelta.y)
    }

    Column {
      id: content

      anchors.centerIn: parent
      spacing: Theme.spaceSm

      Item {
        width: grid.implicitWidth
        height: Math.max(previous.implicitHeight, title.implicitHeight)

        IconButton {
          id: previous

          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          icon: "previous"
          onClicked: root.move(-1)
          onScrolled: delta => root.scroll(delta)
        }

        Pressable {
          id: title

          anchors.centerIn: parent
          implicitWidth: titleLabel.implicitWidth + Theme.spaceMd * 2
          implicitHeight: titleLabel.implicitHeight + Theme.spaceSm
          onClicked: root.showCurrent()
          onScrolled: delta => root.scroll(delta)

          Label {
            id: titleLabel

            anchors.centerIn: parent
            text: root.locale.standaloneMonthName(root.month) + " " + root.year
            size: Theme.fontTitle
            font.weight: Font.DemiBold
          }
        }

        IconButton {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          icon: "more"
          onClicked: root.move(1)
          onScrolled: delta => root.scroll(delta)
        }
      }

      Grid {
        id: grid

        columns: 7
        spacing: Theme.spaceXs

        Repeater {
          model: 7

          Label {
            required property int index

            width: root.cell
            height: root.cell
            horizontalAlignment: Text.AlignHCenter
            text: root.locale.dayName((root.locale.firstDayOfWeek + index) % 7, Locale.ShortFormat)
            size: Theme.fontSmall
            color: Theme.muted
          }
        }

        Repeater {
          model: root.days

          Rectangle {
            id: day

            required property var modelData
            readonly property bool isToday: modelData.date.toDateString() === root.today

            width: root.cell
            height: root.cell
            radius: Theme.radiusMd
            color: isToday ? Theme.accent : "transparent"

            Label {
              anchors.centerIn: parent
              text: day.modelData.day
              color: {
                if (day.isToday) return Theme.accentText;
                return day.modelData.inMonth ? Theme.text : Theme.muted;
              }
            }
          }
        }
      }
    }
  }
}
