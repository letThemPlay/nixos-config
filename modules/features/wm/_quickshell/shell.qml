import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        anchors.top: true
        anchors.horizontalCenter: true
        
        // Tells the layer shell not to reserve empty space so it floats cleanly
        exclusionMode: ExclusionMode.None 
        
        color: "transparent"

        DynamicPill {}
    }
}

