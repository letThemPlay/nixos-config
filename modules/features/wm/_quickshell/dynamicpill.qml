import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: pillRoot
    
    color: "#11111b" 
    border.color: "#313244"
    border.width: 1
    radius: 30
    implicitHeight: 42

    // --- REFACTORED MPRIS SELECTION LOGIC ---
    
    // 1. Locate the best available active player safely from the model array.
    // This avoids querying property paths on empty or uninitialized objects.
    property var activePlayer: {
        for (var i = 0; i < Mpris.players.count; i++) {
            var p = Mpris.players.get(i);
            // Skip playerctld if it's currently hollow, or grab any running player
            if (p && p.busName !== "org.mpris.MediaPlayer2.playerctld" && p.playbackState === MprisPlaybackState.Playing) {
                return p;
            }
        }
        // Fallback: If nothing is actively playing, try to grab the first available media source
        return Mpris.players.count > 0 ? Mpris.players.get(0) : null;
    }

    // 2. Check explicitly if a valid player exists and is currently Playing
    property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing

    // Dynamic Sizing
    implicitWidth: isPlaying ? mediaLayout.implicitWidth + 32 : dateLayout.implicitWidth + 32
    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuint }
    }

    // Local System Clock Engine
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            var d = new Date();
            timeText.text = d.toLocaleTimeString(Qt.locale(), "hh:mm");
            dateText.text = d.toLocaleDateString(Qt.locale(), "ddd d MMM");
        }
    }

    // VIEW A: Static Clock layout
    RowLayout {
        id: dateLayout
        anchors.centerIn: parent
        opacity: !pillRoot.isPlaying ? 1.0 : 0.0
        spacing: 12
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text { id: timeText; color: "#cdd6f4"; font.bold: true; font.pixelSize: 14 }
        Text { id: dateText; color: "#a6adc8"; font.pixelSize: 12 }
    }

    // VIEW B: Media Layout (Renders smoothly when isPlaying resolves true)
    RowLayout {
        id: mediaLayout
        anchors.centerIn: parent
        opacity: pillRoot.isPlaying ? 1.0 : 0.0
        spacing: 16
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            width: 8; height: 8; radius: 4
            color: "#a6e3a1" 
        }

        ColumnLayout {
            spacing: 2
            Text {
                // Safeguard against missing metadata or uninitialized players
                text: (pillRoot.activePlayer && pillRoot.activePlayer.trackTitle) ? pillRoot.activePlayer.trackTitle : "Unknown Track"
                color: "#cdd6f4"
                font.bold: true
                font.pixelSize: 13
                Layout.maximumWidth: 200
                elide: Text.ElideRight
            }
            Text {
                text: (pillRoot.activePlayer && pillRoot.activePlayer.trackArtist) ? pillRoot.activePlayer.trackArtist : "Unknown Artist"
                color: "#bac2de"
                font.pixelSize: 11
                Layout.maximumWidth: 200
                elide: Text.ElideRight
            }
        }
    }
}
