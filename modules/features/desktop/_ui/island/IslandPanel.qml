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

  readonly property bool hasNotifier: Settings.surfaces.includes("notifier")

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
    NightLight.refresh();
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

  component Meter: Row {
    required property string measure
    required property real value

    spacing: Theme.spaceSm

    Label {
      anchors.verticalCenter: parent.verticalCenter
      text: parent.measure
      size: Theme.fontSmall
      color: Theme.muted
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: Theme.sizeSidePanel / 5
      height: Theme.spaceXs
      radius: height / 2
      color: Qt.alpha(Theme.outline, 0.5)

      Rectangle {
        width: parent.width * Math.max(0, parent.parent.value)
        height: parent.height
        radius: parent.radius
        color: Theme.accent

        Behavior on width {
          NumberAnimation { duration: Theme.motionNormal }
        }
      }
    }

    Percent {
      anchors.verticalCenter: parent.verticalCenter
      level: Math.max(0, parent.value)
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

        Repeater {
          model: ScriptModel {
            values: root.expanded ? Activities.keys : []
          }

          ActivityRow {
            required property string modelData

            width: parent.width
            activityKey: modelData
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

        // The system overview, whatever else is going on.
        Column {
          width: parent.width
          visible: root.expanded
          spacing: Theme.spaceMd

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceLg

            Meter {
              measure: "CPU"
              value: SystemLoad.cpu
            }

            Meter {
              measure: "RAM"
              value: SystemLoad.memory
            }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceSm
            visible: Run.has("timerDone")

            Icon {
              anchors.verticalCenter: parent.verticalCenter
              name: "timer"
              size: Theme.iconSmall
              color: Theme.muted
            }

            Repeater {
              model: [5, 10, 25, 60]

              Pressable {
                required property int modelData

                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: minutes.implicitWidth + Theme.spaceMd * 2
                implicitHeight: minutes.implicitHeight + Theme.spaceSm
                onClicked: Activities.startTimer(modelData)

                Label {
                  id: minutes

                  anchors.centerIn: parent
                  text: parent.modelData + " min"
                  size: Theme.fontSmall
                }
              }
            }
          }

          Grid {
            id: controls

            readonly property real tileWidth: (width - spacing * (columns - 1)) / columns

            width: parent.width
            columns: 3
            spacing: Theme.spaceXs

            Tile {
              width: controls.tileWidth
              visible: Wifi.usable || Run.has("networkUi")
              icon: Network.icon
              text: {
                if (Network.kind === "wifi") return Network.name;
                return Network.kind === "wired" ? "Wired" : "Disconnected";
              }
              selected: Network.kind !== "none"
              onClicked: {
                if (Wifi.usable) {
                  Ui.open = "wifi";
                } else {
                  Ui.close();
                  Run.command("networkUi");
                }
              }
            }

            Tile {
              width: controls.tileWidth
              visible: BluetoothDevices.present
              icon: BluetoothDevices.enabled ? "bluetooth" : "bluetoothOff"
              text: "Bluetooth"
              selected: BluetoothDevices.enabled
              onClicked: {
                if (Settings.surfaces.includes("bluetooth")) {
                  Ui.open = "bluetooth";
                } else {
                  Ui.close();
                  Run.command("bluetoothUi");
                }
              }
            }

            Tile {
              width: controls.tileWidth
              visible: root.hasNotifier
              icon: "notificationsPaused"
              text: "Silent"
              selected: root.hasNotifier && Notifications.doNotDisturb
              onClicked: Notifications.doNotDisturb = !Notifications.doNotDisturb
            }

            Tile {
              width: controls.tileWidth
              visible: NightLight.available
              icon: "nightLight"
              text: "Night light"
              selected: NightLight.active
              onClicked: NightLight.toggle()
            }

            Tile {
              width: controls.tileWidth
              icon: "keepAwake"
              text: "Keep awake"
              selected: Ui.keepAwake
              onClicked: Ui.keepAwake = !Ui.keepAwake
            }

            Tile {
              width: controls.tileWidth
              visible: Settings.surfaces.includes("quicksettings")
              icon: "settings"
              text: "More"
              onClicked: Ui.open = "quicksettings"
            }
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
