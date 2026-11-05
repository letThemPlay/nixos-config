import Quickshell
import Quickshell.Io
import QtQuick
import qs.calendar
import qs.common
import qs.notifications
import qs.services

// The center island expanded: the same things it shows in the bar, with room for
// their controls, and the month it stands in for when idle. The card grows out of
// the pill, from the pill's size and place.
Overlay {
  id: root

  surface: "island"

  readonly property real cardHeight: content.implicitHeight + Theme.spaceLg * 2
  readonly property real maxHeight: root.height - Theme.spaceSm * 2

  function grown(from, to) {
    return from + (to - from) * progress;
  }

  function time(seconds) {
    const whole = Math.max(0, Math.floor(seconds));
    const rest = whole % 60;
    return Math.floor(whole / 60) + ":" + (rest < 10 ? "0" : "") + rest;
  }

  onShownChanged: {
    if (shown) month.showCurrent();
  }

  IpcHandler {
    target: "island"

    function toggle(): void {
      Ui.toggle("island");
    }
  }

  // The calendar's bind opens the card that holds it.
  IpcHandler {
    target: "calendar"

    function toggle(): void {
      Ui.toggle("island");
    }
  }

  // A player only reports its position when asked, so this asks while it's seen.
  Timer {
    interval: 1000
    running: root.shown && Media.player !== null
    repeat: true
    triggeredOnStart: true
    onTriggered: Media.player?.positionChanged()
  }

  Panel {
    id: card

    anchors.horizontalCenter: parent.horizontalCenter
    y: Theme.spaceSm
    width: root.grown(LiveActivity.compactWidth, Theme.sizeSidePanel)
    height: root.grown(Theme.sizeBar, Math.min(root.cardHeight, root.maxHeight))
    clip: true
    focus: true

    Keys.onLeftPressed: month.move(-1)
    Keys.onRightPressed: month.move(1)

    // Presses inside the card must not reach the overlay's dismiss area.
    MouseArea {
      anchors.fill: parent
    }

    Flickable {
      x: Theme.spaceLg
      y: Theme.spaceLg
      width: Theme.sizeSidePanel - Theme.spaceLg * 2
      height: Math.min(root.cardHeight, root.maxHeight) - Theme.spaceLg * 2
      contentHeight: content.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      opacity: root.progress

      Column {
        id: content

        width: parent.width
        spacing: Theme.spaceMd

        NotificationCard {
          width: parent.width
          visible: LiveActivity.notification !== null
          notification: LiveActivity.notification
          color: Theme.surfaceRaised
        }

        Row {
          width: parent.width
          spacing: Theme.spaceSm
          visible: Recorder.active

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "recording"
            filled: true
            size: Theme.iconSmall
            color: Theme.danger
          }

          Label {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - stop.implicitWidth - Theme.iconSmall - parent.spacing * 2
            text: "Recording " + Recorder.elapsed
            size: Theme.fontTitle
          }

          Pressable {
            id: stop

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: stopLabel.implicitWidth + Theme.spaceMd * 2
            implicitHeight: stopLabel.implicitHeight + Theme.spaceSm
            color: Qt.alpha(Theme.danger, hovered ? 0.9 : 0.6)
            onClicked: Recorder.stop()

            Label {
              id: stopLabel

              anchors.centerIn: parent
              text: "Stop"
              color: Theme.accentText
            }
          }
        }

        Column {
          id: media

          readonly property var player: Media.player
          readonly property real length: player?.lengthSupported ? player.length : 0

          width: parent.width
          spacing: Theme.spaceSm
          visible: player !== null

          Row {
            width: parent.width
            spacing: Theme.spaceMd

            Rectangle {
              width: Theme.iconHuge
              height: Theme.iconHuge
              radius: Theme.radiusMd
              color: Theme.surfaceRaised
              clip: true

              Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                name: "mediaPlay"
                size: Theme.iconLarge
                color: Theme.muted
              }

              Image {
                id: art

                anchors.fill: parent
                source: media.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
              }
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - Theme.iconHuge - transport.width - parent.spacing * 2

              Label {
                width: parent.width
                text: media.player?.trackTitle ?? ""
                size: Theme.fontTitle
                font.weight: Font.DemiBold
              }

              Label {
                width: parent.width
                visible: text !== ""
                text: media.player?.trackArtist ?? ""
                color: Theme.muted
              }
            }

            Row {
              id: transport

              anchors.verticalCenter: parent.verticalCenter

              IconButton {
                icon: "mediaPrevious"
                iconSize: Theme.iconMedium
                opacity: media.player?.canGoPrevious ? 1 : 0.4
                onClicked: {
                  if (media.player?.canGoPrevious) media.player.previous();
                }
              }

              IconButton {
                icon: Media.playing ? "mediaPause" : "mediaPlay"
                iconSize: Theme.iconMedium
                onClicked: media.player?.togglePlaying()
              }

              IconButton {
                icon: "mediaNext"
                iconSize: Theme.iconMedium
                opacity: media.player?.canGoNext ? 1 : 0.4
                onClicked: {
                  if (media.player?.canGoNext) media.player.next();
                }
              }
            }
          }

          Row {
            width: parent.width
            spacing: Theme.spaceSm
            visible: media.length > 0

            Label {
              anchors.verticalCenter: parent.verticalCenter
              text: root.time(media.player?.position ?? 0)
              size: Theme.fontSmall
              color: Theme.muted
            }

            Slider {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - elapsedEnd.implicitWidth * 2 - parent.spacing * 2
              enabled: media.player?.canSeek ?? false
              value: media.length > 0 ? (media.player?.position ?? 0) / media.length : 0
              onMoved: next => media.player.position = next * media.length
            }

            Label {
              id: elapsedEnd

              anchors.verticalCenter: parent.verticalCenter
              text: root.time(media.length)
              size: Theme.fontSmall
              color: Theme.muted
            }
          }
        }

        Item {
          width: parent.width
          height: month.implicitHeight

          // Over the month, the wheel changes the month, unless it's needed to reach
          // the rest of a card too tall for the screen.
          MouseArea {
            anchors.fill: parent
            enabled: root.cardHeight <= root.maxHeight
            onWheel: event => month.scroll(event.angleDelta.y)
          }

          MonthView {
            id: month

            anchors.horizontalCenter: parent.horizontalCenter
          }
        }
      }
    }
  }
}
