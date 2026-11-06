import Quickshell
import Quickshell.Io
import QtQuick
import qs.calendar
import qs.common
import qs.notifications
import qs.quicksettings
import qs.services

// The center island expanded or focused, as LiveActivity says. The card grows out of
// the pill, from the pill's size and place.
//
// Expanded is live: what's happening carries on arriving and leaving while it's open,
// above the system overview. Pressing something there focuses it, for its fuller
// controls. Neither changes what's active, so collapsing returns to the current pill.
Overlay {
  id: root

  surface: "island"
  openDuration: LiveActivity.motion

  readonly property bool expanded: !LiveActivity.isFocused
  readonly property string focusedOn: LiveActivity.isFocused ? LiveActivity.focusedOn : ""

  // Noted as the card opens. The calendar doesn't sit under anything going on, and this
  // doesn't change while open, so pausing a track doesn't make it appear.
  property bool idleAtOpening: false

  readonly property var notification: LiveActivity.notification
  readonly property bool isCritical: LiveActivity.critical !== null

  readonly property var player: Media.player
  readonly property real trackLength: player?.lengthSupported ? player.length : 0

  readonly property bool showsMonth: focusedOn === "month" || (expanded && idleAtOpening)

  readonly property real cardHeight: content.implicitHeight + Theme.spaceLg * 2
  readonly property real maxHeight: root.height - Theme.spaceSm * 2

  // Follows what's in the card, which can now change while it's open. Not while it
  // opens, which grows it anyway.
  property real shownHeight: Math.min(cardHeight, maxHeight)

  Behavior on shownHeight {
    enabled: root.progress === 1

    NumberAnimation { duration: LiveActivity.motion; easing.type: Easing.OutCubic }
  }

  // Whether anything going on sits above the overview, which a line then separates.
  readonly property bool live: notification !== null || Recorder.active || Microphone.active || player !== null

  function grown(from, to) {
    return from + (to - from) * progress;
  }

  function time(seconds) {
    const whole = Math.max(0, Math.floor(seconds));
    const rest = whole % 60;
    return Math.floor(whole / 60) + ":" + (rest < 10 ? "0" : "") + rest;
  }

  onShownChanged: {
    if (!shown) return;

    idleAtOpening = LiveActivity.settled === "clock";
    month.showCurrent();
  }

  Binding {
    target: SystemLoad
    property: "watching"
    value: root.shown && root.expanded
  }

  // What was focused has gone, so there's nothing left to look at closely. Only while
  // open: collapsing leaves the presentation as it was, and this mustn't reopen the card.
  Connections {
    target: root
    enabled: root.shown

    function onNotificationChanged() {
      if (root.focusedOn === "notification" && root.notification === null) LiveActivity.expand();
    }

    function onPlayerChanged() {
      if (root.focusedOn === "media" && root.player === null) LiveActivity.expand();
    }
  }

  IpcHandler {
    target: "island"

    function toggle(): void {
      if (root.shown) LiveActivity.collapse();
      else LiveActivity.expand();
    }

    // Straight to the view of whatever's current, past the expanded card.
    function focusCurrent(): void {
      if (root.shown) LiveActivity.collapse();
      else LiveActivity.focusCurrent();
    }
  }

  // The calendar's bind opens the month, whatever else is happening.
  IpcHandler {
    target: "calendar"

    function toggle(): void {
      if (root.shown) LiveActivity.collapse();
      else LiveActivity.focusOn("month", true);
    }
  }

  // A player only reports its position when asked, so this asks while it's seen.
  Timer {
    interval: 1000
    running: root.shown && root.player !== null
    repeat: true
    triggeredOnStart: true
    onTriggered: root.player?.positionChanged()
  }

  // One of the overview's figures: an icon above, say, "CPU 12%", or a dash until the
  // first reading.
  component Figure: Column {
    required property string icon
    required property string measure
    required property real value

    spacing: Theme.spaceXs

    Icon {
      name: parent.icon
      size: Theme.iconMedium
      color: Theme.accent
    }

    Label {
      width: parent.width
      text: parent.measure + " " + (parent.value < 0 ? "—" : Math.round(parent.value * 100) + "%")
      size: Theme.fontHeading
      font.weight: Font.DemiBold
    }
  }

  // A line of the overview: what it is, and how it stands.
  component Fact: Item {
    required property string measure
    required property string value

    implicitHeight: valueLabel.implicitHeight

    Label {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: parent.measure
      color: Theme.muted
    }

    Label {
      id: valueLabel

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: parent.value
    }
  }

  component Artwork: Rectangle {
    required property int side

    width: side
    height: side
    radius: Theme.radiusMd
    color: Theme.surfaceRaised
    clip: true

    Icon {
      anchors.centerIn: parent
      visible: art.status !== Image.Ready
      name: "mediaPlay"
      size: parent.side / 2
      color: Theme.muted
    }

    Image {
      id: art

      anchors.fill: parent
      source: root.player?.trackArtUrl ?? ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }
  }

  component Transport: Row {
    property int playSize: Theme.iconMedium

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: "mediaPrevious"
      iconSize: Theme.iconMedium
      opacity: root.player?.canGoPrevious ? 1 : 0.4
      onClicked: {
        if (root.player?.canGoPrevious) root.player.previous();
      }
    }

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: Media.playing ? "mediaPause" : "mediaPlay"
      iconSize: parent.playSize
      onClicked: root.player?.togglePlaying()
    }

    IconButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: "mediaNext"
      iconSize: Theme.iconMedium
      opacity: root.player?.canGoNext ? 1 : 0.4
      onClicked: {
        if (root.player?.canGoNext) root.player.next();
      }
    }
  }

  component Seeker: Row {
    spacing: Theme.spaceSm
    visible: root.trackLength > 0

    Label {
      anchors.verticalCenter: parent.verticalCenter
      text: root.time(root.player?.position ?? 0)
      size: Theme.fontSmall
      color: Theme.muted
    }

    Slider {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - total.implicitWidth * 2 - parent.spacing * 2
      enabled: root.player?.canSeek ?? false
      value: root.trackLength > 0 ? (root.player?.position ?? 0) / root.trackLength : 0
      onMoved: next => root.player.position = next * root.trackLength
    }

    Label {
      id: total

      anchors.verticalCenter: parent.verticalCenter
      text: root.time(root.trackLength)
      size: Theme.fontSmall
      color: Theme.muted
    }
  }

  Panel {
    id: card

    anchors.horizontalCenter: parent.horizontalCenter
    y: Theme.spaceSm
    width: root.grown(LiveActivity.compactWidth, Theme.sizeSidePanel)
    height: root.grown(Theme.sizeBar, root.shownHeight)
    clip: true
    focus: true

    Keys.onLeftPressed: {
      if (root.showsMonth) month.move(-1);
    }
    Keys.onRightPressed: {
      if (root.showsMonth) month.move(1);
    }

    // Steps back where it came from there; otherwise the overlay closes it.
    Keys.onEscapePressed: event => {
      if (LiveActivity.isFocused && !LiveActivity.focusedDirectly) LiveActivity.expand();
      else event.accepted = false;
    }

    // Presses inside the card must not reach the overlay's dismiss area.
    MouseArea {
      anchors.fill: parent
    }

    Flickable {
      x: Theme.spaceLg
      y: Theme.spaceLg
      width: Theme.sizeSidePanel - Theme.spaceLg * 2
      height: root.shownHeight - Theme.spaceLg * 2
      contentHeight: content.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      opacity: root.progress

      Column {
        id: content

        width: parent.width
        spacing: Theme.spaceMd

        // Back to the overview, where it came from there.
        IconButton {
          visible: LiveActivity.isFocused && !LiveActivity.focusedDirectly
          icon: "previous"
          iconSize: Theme.iconMedium
          onClicked: LiveActivity.expand()
        }

        // A notification, in brief. Pressing it gives the whole of it.
        Pressable {
          width: parent.width
          implicitHeight: Theme.sizeField + Theme.spaceSm
          visible: root.expanded && root.notification !== null
          color: hovered ? Theme.outline : Theme.surfaceRaised
          border.width: 1
          border.color: root.isCritical ? Theme.danger : Qt.alpha(Theme.outline, 0.5)
          onClicked: LiveActivity.focusOn("notification", false)

          AppIcon {
            id: briefIcon

            anchors.left: parent.left
            anchors.leftMargin: Theme.spaceMd
            anchors.verticalCenter: parent.verticalCenter
            size: Theme.iconMedium
            name: root.notification?.image || root.notification?.appIcon || root.notification?.desktopEntry || ""
          }

          Column {
            anchors.left: briefIcon.right
            anchors.right: briefClose.left
            anchors.leftMargin: Theme.spaceMd
            anchors.rightMargin: Theme.spaceSm
            anchors.verticalCenter: parent.verticalCenter

            Label {
              width: parent.width
              text: root.notification?.summary ?? ""
              color: root.isCritical ? Theme.danger : Theme.text
              font.weight: Font.DemiBold
            }

            Label {
              width: parent.width
              text: {
                const preview = (root.notification?.body ?? "").split("\n")[0];
                return (root.notification?.appName ?? "") + (preview === "" ? "" : "  " + preview);
              }
              size: Theme.fontSmall
              color: Theme.muted
            }
          }

          IconButton {
            id: briefClose

            anchors.right: parent.right
            anchors.rightMargin: Theme.spaceSm
            anchors.verticalCenter: parent.verticalCenter
            icon: "close"
            onClicked: root.notification?.dismiss()
          }
        }

        NotificationCard {
          width: parent.width
          visible: root.focusedOn === "notification" && root.notification !== null
          notification: root.notification
          color: Theme.surfaceRaised
          elevated: false
        }

        AudioRow {
          width: parent.width
          visible: root.focusedOn === "audio" && devices.length > 0
          output: true
          icon: "volumeHigh"
          mutedIcon: "volumeMuted"
          tracking: root.shown && root.focusedOn === "audio"
        }

        AudioRow {
          width: parent.width
          visible: root.focusedOn === "audio" && devices.length > 0
          output: false
          icon: "microphone"
          mutedIcon: "microphoneMuted"
          tracking: root.shown && root.focusedOn === "audio"
        }

        Row {
          width: parent.width
          spacing: Theme.spaceSm
          visible: root.expanded && Recorder.active

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

        Row {
          width: parent.width
          spacing: Theme.spaceSm
          visible: root.expanded && Microphone.active

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Microphone.muted ? "microphoneMuted" : "microphone"
            size: Theme.iconSmall
            color: Microphone.muted ? Theme.muted : Theme.warning
          }

          Label {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Theme.iconSmall - parent.spacing
            text: Microphone.users ? "Microphone in use by " + Microphone.users : "Microphone in use"
          }
        }

        // The player beside the overview. Pressing the track gives the fuller one.
        Column {
          width: parent.width
          spacing: Theme.spaceSm
          visible: root.expanded && root.player !== null

          Item {
            width: parent.width
            height: Theme.iconHuge

            Pressable {
              anchors.left: parent.left
              anchors.right: briefTransport.left
              anchors.rightMargin: Theme.spaceSm
              height: parent.height
              onClicked: LiveActivity.focusOn("media", false)

              Artwork {
                id: briefArt

                side: Theme.iconHuge
              }

              Column {
                anchors.left: briefArt.right
                anchors.right: parent.right
                anchors.leftMargin: Theme.spaceMd
                anchors.verticalCenter: parent.verticalCenter

                Label {
                  width: parent.width
                  text: root.player?.trackTitle ?? ""
                  font.weight: Font.DemiBold
                }

                Label {
                  width: parent.width
                  visible: text !== ""
                  text: root.player?.trackArtist ?? ""
                  size: Theme.fontSmall
                  color: Theme.muted
                }
              }
            }

            Transport {
              id: briefTransport

              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Seeker {
            width: parent.width
          }
        }

        // The player with room for it.
        Column {
          width: parent.width
          spacing: Theme.spaceMd
          visible: root.focusedOn === "media" && root.player !== null

          Row {
            width: parent.width
            spacing: Theme.spaceMd

            Artwork {
              id: fullArt

              side: Theme.sizeSidePanel / 3
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - fullArt.width - parent.spacing
              spacing: Theme.spaceXs

              Label {
                width: parent.width
                text: root.player?.trackTitle ?? ""
                size: Theme.fontTitle
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 3
              }

              Label {
                width: parent.width
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                color: Theme.muted
              }

              Label {
                width: parent.width
                visible: text !== ""
                text: root.player?.trackAlbum ?? ""
                size: Theme.fontSmall
                color: Theme.muted
              }
            }
          }

          Transport {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceMd
            playSize: Theme.iconLarge
          }

          Seeker {
            width: parent.width
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Theme.outline
          opacity: 0.5
          visible: root.expanded && root.live
        }

        // The system overview, whatever else is going on. Only to read: quick settings
        // has the controls.
        Column {
          width: parent.width
          visible: root.expanded
          spacing: Theme.spaceMd

          Label {
            text: "System Overview"
            size: Theme.fontHeading
            color: Theme.muted
          }

          Row {
            id: figures

            readonly property int count: SystemLoad.diskReadable ? 3 : 2
            readonly property real figureWidth: (width - spacing * (count - 1)) / count

            width: parent.width
            spacing: Theme.spaceMd

            Figure {
              width: figures.figureWidth
              icon: "cpu"
              measure: "CPU"
              value: SystemLoad.cpu
            }

            Figure {
              width: figures.figureWidth
              icon: "ram"
              measure: "RAM"
              value: SystemLoad.memory
            }

            Figure {
              width: figures.figureWidth
              visible: SystemLoad.diskReadable
              icon: "disk"
              measure: "Disk"
              value: SystemLoad.disk
            }
          }

          Fact {
            width: parent.width
            measure: "Network"
            value: {
              if (Network.kind === "wifi") return Network.name || "Wi-Fi";
              return Network.kind === "wired" ? "Wired" : "Disconnected";
            }
          }

          Fact {
            width: parent.width
            visible: Battery.present
            measure: "Battery"
            value: Battery.percent + "%" + (Battery.charging ? " · Charging" : "")
          }
        }

        Item {
          width: parent.width
          height: month.implicitHeight
          visible: root.showsMonth

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
