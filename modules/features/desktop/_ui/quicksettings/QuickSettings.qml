import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import qs.common
import qs.notifications
import qs.services

// The controls that don't deserve an application of their own, under the bar's
// right island beside the button that opens it. A row is left out where the
// machine has nothing for it.
Overlay {
  id: root

  surface: "quicksettings"

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool hasNotifier: Settings.surfaces.includes("notifier")

  function remaining(seconds) {
    const minutes = Math.round(seconds / 60);
    const hours = Math.floor(minutes / 60);
    return hours > 0 ? hours + " h " + (minutes % 60) + " min" : minutes + " min";
  }

  onShownChanged: {
    if (!shown) return;

    Brightness.refresh(false);
    NightLight.refresh();
  }

  IpcHandler {
    target: "quicksettings"

    function toggle(): void {
      Ui.toggle("quicksettings");
    }
  }

  Panel {
    id: panel

    x: root.width - width - Theme.spaceSm
    y: Theme.sizeBar + Theme.spaceSm * 2 - (1 - root.progress) * Theme.spaceXl
    width: Theme.sizeSidePanel
    height: Math.min(content.implicitHeight + Theme.spaceLg * 2, root.height - y - Theme.spaceSm)
    opacity: root.progress

    // Presses inside the panel must not reach the overlay's dismiss area.
    MouseArea {
      anchors.fill: parent
    }

    Flickable {
      anchors.fill: parent
      anchors.margins: Theme.spaceLg
      contentHeight: content.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: content

        width: parent.width
        spacing: Theme.spaceMd

        AudioRow {
          width: parent.width
          output: true
          icon: "volumeHigh"
          mutedIcon: "volumeMuted"
          tracking: root.shown
        }

        AudioRow {
          width: parent.width
          output: false
          icon: "microphone"
          mutedIcon: "microphoneMuted"
          tracking: root.shown
        }

        Row {
          width: parent.width
          spacing: Theme.spaceSm
          visible: Run.has("brightnessSet")

          Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.iconMedium + Theme.spaceSm * 2
            height: width

            Icon {
              anchors.centerIn: parent
              name: "brightness"
              size: Theme.iconMedium
            }
          }

          Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Theme.iconMedium - Theme.spaceSm * 2 - brightnessLabel.width - parent.spacing * 2
            minimum: 0.01
            value: Brightness.level
            onMoved: level => Brightness.set(level)
          }

          Percent {
            id: brightnessLabel

            anchors.verticalCenter: parent.verticalCenter
            level: Brightness.level
            color: Theme.muted
          }
        }

        Row {
          id: profiles

          readonly property var choices: PowerMode.hasPerformance ? ["saver", "balanced", "performance"] : ["saver", "balanced"]

          width: parent.width
          spacing: Theme.spaceXs
          visible: PowerMode.available

          Repeater {
            model: profiles.choices

            Tile {
              required property string modelData

              width: (profiles.width - profiles.spacing * (profiles.choices.length - 1)) / profiles.choices.length
              icon: ({ "saver": "profileSaver", "balanced": "profileBalanced", "performance": "profilePerformance" })[modelData]
              text: ({ "saver": "Saver", "balanced": "Balanced", "performance": "Performance" })[modelData]
              selected: PowerMode.current === modelData
              onClicked: PowerMode.choose(modelData)
            }
          }
        }

        Row {
          id: toggles

          readonly property int count: (root.adapter ? 1 : 0) + (root.hasNotifier ? 1 : 0) + (NightLight.available ? 1 : 0) + 1
          readonly property real tileWidth: (width - spacing * (count - 1)) / count

          width: parent.width
          spacing: Theme.spaceXs

          Tile {
            width: toggles.tileWidth
            visible: root.adapter !== null
            icon: root.adapter?.enabled ? "bluetooth" : "bluetoothOff"
            text: "Bluetooth"
            selected: root.adapter?.enabled ?? false
            onClicked: {
              if (root.adapter) root.adapter.enabled = !root.adapter.enabled;
            }
          }

          Tile {
            width: toggles.tileWidth
            visible: root.hasNotifier
            icon: "notificationsPaused"
            text: "Silent"
            selected: root.hasNotifier && Notifications.doNotDisturb
            onClicked: Notifications.doNotDisturb = !Notifications.doNotDisturb
          }

          Tile {
            width: toggles.tileWidth
            visible: NightLight.available
            icon: "nightLight"
            text: "Night light"
            selected: NightLight.active
            onClicked: NightLight.toggle()
          }

          Tile {
            width: toggles.tileWidth
            icon: "keepAwake"
            text: "Keep awake"
            selected: Ui.keepAwake
            onClicked: Ui.keepAwake = !Ui.keepAwake
          }
        }

        Row {
          id: recording

          readonly property int count: Recorder.active ? 1 : 3
          readonly property real tileWidth: (width - spacing * (count - 1)) / count

          width: parent.width
          spacing: Theme.spaceXs
          visible: Recorder.available

          Tile {
            width: recording.tileWidth
            visible: Recorder.active
            icon: "recordStop"
            text: "Stop recording, " + Recorder.elapsed
            danger: true
            onClicked: Recorder.stop()
          }

          Tile {
            width: recording.tileWidth
            visible: !Recorder.active
            icon: "recordScreen"
            text: "Record screen"
            onClicked: Recorder.start("screen")
          }

          Tile {
            width: recording.tileWidth
            visible: !Recorder.active
            icon: "recordRegion"
            text: "Record region"
            onClicked: Recorder.start("region")
          }

          Tile {
            width: recording.tileWidth
            visible: !Recorder.active
            icon: "recordAudio"
            text: "System audio"
            selected: Recorder.withAudio
            onClicked: Recorder.withAudio = !Recorder.withAudio
          }
        }

        Pressable {
          width: parent.width
          implicitHeight: Theme.sizeBarItem + Theme.spaceSm
          visible: Wifi.usable || Run.has("networkUi")
          onClicked: {
            if (Wifi.usable) {
              Ui.open = "wifi";
            } else {
              Ui.close();
              Run.command("networkUi");
            }
          }

          Icon {
            id: networkIcon

            anchors.left: parent.left
            anchors.leftMargin: Theme.spaceSm
            anchors.verticalCenter: parent.verticalCenter
            name: Network.icon
            size: Theme.iconSmall
            color: parent.foreground
          }

          Label {
            anchors.left: networkIcon.right
            anchors.right: networkMore.left
            anchors.leftMargin: Theme.spaceSm
            anchors.verticalCenter: parent.verticalCenter
            text: {
              if (Network.kind === "wifi") return Network.name;
              return Network.kind === "wired" ? "Wired" : "Disconnected";
            }
            color: parent.foreground
          }

          Icon {
            id: networkMore

            anchors.right: parent.right
            anchors.rightMargin: Theme.spaceSm
            anchors.verticalCenter: parent.verticalCenter
            name: "more"
            size: Theme.iconSmall
            color: Theme.muted
          }
        }

        Row {
          spacing: Theme.spaceSm
          visible: Battery.present

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Battery.icon
            size: Theme.iconSmall
            filled: true
          }

          Label {
            anchors.verticalCenter: parent.verticalCenter
            text: {
              if (Battery.charging) return Battery.percent + "%, charging";
              if (Battery.timeToEmpty > 0) return Battery.percent + "%, " + root.remaining(Battery.timeToEmpty) + " left";
              return Battery.percent + "%";
            }
            color: Theme.muted
          }
        }
      }
    }
  }
}
