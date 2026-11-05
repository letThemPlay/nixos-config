import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.WindowManager
import QtQuick
import qs.calendar
import qs.common
import qs.notifications
import qs.quicksettings
import qs.services

// The center island expanded: whatever it was showing, with room for its controls,
// or the month when it was only showing the time. The card grows out of the pill, from
// the pill's size and place.
//
// What it holds is decided as it opens and kept, so pausing a track in the card doesn't
// swap the track for a calendar under the pointer. A recording always shows, as the
// way to stop it, and a paused track shows above the month, as nothing else reaches it.
Overlay {
  id: root

  surface: "island"
  openDuration: LiveActivity.motion

  property string context: "clock"
  property string requested: ""

  readonly property bool showsNotification: context === "notification" && LiveActivity.notification !== null
  readonly property bool showsMedia: {
    if (Media.player === null) return false;
    return context === "media" || context === "clock" || (context === "recording" && Media.playing);
  }
  readonly property bool showsAudio: context === "audio"
  readonly property bool showsIdle: context === "clock"
  readonly property bool showsMonth: {
    if (context === "calendar" || context === "clock") return true;
    return !showsNotification && !showsMedia && !showsAudio && !Recorder.active;
  }

  readonly property real cardHeight: content.implicitHeight + Theme.spaceLg * 2
  readonly property real maxHeight: root.height - Theme.spaceSm * 2

  // The focused window as the card opened: it takes the keyboard, and with it the focus
  // this is asking about.
  property var focused: null

  // The workspace on the output holding that window.
  readonly property string workspace: {
    if (!showsIdle) return "";

    const screen = focused?.screens?.[0] ?? Quickshell.screens[0];
    const sets = WindowManager.screenProjection(screen)?.windowsets ?? [];
    const shown = sets.filter(set => set.shouldDisplay);
    const active = shown.findIndex(set => set.active);

    return active < 0 ? "" : "Workspace " + (shown[active].name || active + 1);
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

    focused = ToplevelManager.activeToplevel;
    context = requested || LiveActivity.opening;
    requested = "";
    month.showCurrent();
    NightLight.refresh();
  }

  Binding {
    target: SystemLoad
    property: "watching"
    value: root.shown && root.showsIdle
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

  // Once it's been dismissed or acted on, there's nothing left to show.
  Connections {
    target: LiveActivity

    function onNotificationChanged() {
      if (root.shown && root.context === "notification" && LiveActivity.notification === null) Ui.close();
    }
  }

  IpcHandler {
    target: "island"

    function toggle(): void {
      Ui.toggle("island");
    }
  }

  // The calendar's bind opens the card on the month, whatever else is happening.
  IpcHandler {
    target: "calendar"

    function toggle(): void {
      if (!root.shown) root.requested = "calendar";
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

    Keys.onLeftPressed: {
      if (root.showsMonth) month.move(-1);
    }
    Keys.onRightPressed: {
      if (root.showsMonth) month.move(1);
    }

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

        Column {
          width: parent.width
          visible: root.showsIdle
          spacing: Theme.spaceMd

          Column {
            width: parent.width

            Label {
              width: parent.width
              visible: text !== ""
              text: root.workspace
              size: Theme.fontTitle
              font.weight: Font.DemiBold
            }

            Label {
              width: parent.width
              visible: text !== ""
              text: root.focused?.title ?? ""
              color: Theme.muted
            }
          }

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

        NotificationCard {
          width: parent.width
          visible: root.showsNotification
          notification: LiveActivity.notification
          color: Theme.surfaceRaised
        }

        AudioRow {
          width: parent.width
          visible: root.showsAudio && devices.length > 0
          output: true
          icon: "volumeHigh"
          mutedIcon: "volumeMuted"
          tracking: root.shown && root.showsAudio
        }

        AudioRow {
          width: parent.width
          visible: root.showsAudio && devices.length > 0
          output: false
          icon: "microphone"
          mutedIcon: "microphoneMuted"
          tracking: root.shown && root.showsAudio
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
            onClicked: {
              Recorder.stop();
              if (root.context === "recording") Ui.close();
            }

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
          readonly property int artSize: Theme.sizeSidePanel / 3

          width: parent.width
          spacing: Theme.spaceMd
          visible: root.showsMedia

          Row {
            width: parent.width
            spacing: Theme.spaceMd

            Rectangle {
              width: media.artSize
              height: media.artSize
              radius: Theme.radiusMd
              color: Theme.surfaceRaised
              clip: true

              Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                name: "mediaPlay"
                size: Theme.iconHuge
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
              width: parent.width - media.artSize - parent.spacing
              spacing: Theme.spaceXs

              Label {
                width: parent.width
                text: media.player?.trackTitle ?? ""
                size: Theme.fontTitle
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 3
              }

              Label {
                width: parent.width
                visible: text !== ""
                text: media.player?.trackArtist ?? ""
                color: Theme.muted
              }

              Label {
                width: parent.width
                visible: text !== ""
                text: media.player?.trackAlbum ?? ""
                size: Theme.fontSmall
                color: Theme.muted
              }
            }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceMd

            IconButton {
              anchors.verticalCenter: parent.verticalCenter
              icon: "mediaPrevious"
              iconSize: Theme.iconMedium
              opacity: media.player?.canGoPrevious ? 1 : 0.4
              onClicked: {
                if (media.player?.canGoPrevious) media.player.previous();
              }
            }

            IconButton {
              anchors.verticalCenter: parent.verticalCenter
              icon: Media.playing ? "mediaPause" : "mediaPlay"
              iconSize: Theme.iconLarge
              onClicked: media.player?.togglePlaying()
            }

            IconButton {
              anchors.verticalCenter: parent.verticalCenter
              icon: "mediaNext"
              iconSize: Theme.iconMedium
              opacity: media.player?.canGoNext ? 1 : 0.4
              onClicked: {
                if (media.player?.canGoNext) media.player.next();
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
