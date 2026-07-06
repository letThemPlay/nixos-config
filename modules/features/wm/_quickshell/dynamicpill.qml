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

    // --- BULLETPROOF MPRIS BINDINGS ---
    
    // 1. Establish an explicit native dependency on the model structure count
    property int playerCount: Mpris.players ? Mpris.players.count : 0
    
    // 2. Safely resolve the active media player object reference
    property var activePlayer: playerCount > 0 ? Mpris.players.get(0) : null
    
    // 3. Use the player's native, built-in 'isPlaying' boolean property
    property bool isPlaying: activePlayer !== null ? activePlayer.isPlaying : false

    // Smooth pill transitions driven directly by the boolean
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

    // VIEW A: Static Clock Layout
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

    // VIEW B: Dynamic Media Tracker Layout
    RowLayout {
        id: mediaLayout
        anchors.centerIn: parent
        opacity: pillRoot.isPlaying ? 1.0 : 0.0
        spacing: 16
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Audio Active Indicator Dot
        Rectangle {
            width: 8; height: 8; radius: 4
            color: "#a6e3a1" 
        }

        ColumnLayout {
            spacing: 2
            Text {
                // Read safe properties mapped on the MprisPlayer layout spec
                text: (pillRoot.activePlayer && pillRoot.activePlayer.trackTitle) ? pillRoot.activePlayer.trackTitle : "Loading Track..."
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
