import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: pillRoot
    
    // Smooth pill aesthetics
    color: "#11111b" // Catppuccin Mocha Crust / Deep Black
    border.color: "#313244"
    border.width: 1
    radius: 30
    height: 42

    // Internal paddings
    layer.enabled: true

    // Track state: check if an active player is actively playing audio
    property bool isPlaying: Mpris.players.length > 0 && Mpris.players[0].playbackState === MprisPlayer.Playing

    // Dynamic Island Sizing Transitions
    width: isPlaying ? mediaLayout.implicitWidth + 32 : dateLayout.implicitWidth + 32
    Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuint }
    }

    // Timer to drive the local clock engine
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            var d = new Date();
            timeText.text = d.toLocaleTimeString(Qt.locale(), "hh:mm");
            dateText.text = d.toLocaleDateString(Qt.locale(), "ddd d MMM");
        }
    }

    // VIEW A: Simple Date & Time layout (Default static view)
    RowLayout {
        id: dateLayout
        anchors.centerIn: parent
        opacity: !pillRoot.isPlaying ? 1.0 : 0.0
        spacing: 12
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            id: timeText
            color: "#cdd6f4"
            font.bold: true
            font.pixelSize: 14
        }
        Text {
            id: dateText
            color: "#a6adc8"
            font.pixelSize: 12
        }
    }

    // VIEW B: Active Media Tracker Layout (Expands over clock when playing)
    RowLayout {
        id: mediaLayout
        anchors.centerIn: parent
        opacity: pillRoot.isPlaying ? 1.0 : 0.0
        spacing: 16
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Green audio pulsing icon anchor 
        Rectangle {
            width: 8; height: 8; radius: 4
            color: "#a6e3a1" 
        }

        ColumnLayout {
            spacing: 2
            Text {
                text: Mpris.players.length > 0 ? Mpris.players[0].trackTitle : ""
                color: "#cdd6f4"
                font.bold: true
                font.pixelSize: 13
                Layout.maximumWidth: 200
                elide: Text.ElideRight
            }
            Text {
                text: Mpris.players.length > 0 ? Mpris.players[0].trackArtist : ""
                color: "#bac2de"
                font.pixelSize: 11
                Layout.maximumWidth: 200
                elide: Text.ElideRight
            }
        }
    }
}

