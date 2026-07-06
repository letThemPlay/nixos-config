import QtQuick
import Quickshell
import Quickshell.Wayland
import "." 

ShellRoot {
    PanelWindow {
        id: rootPanel
        
        // Attach to the top edge of the screen
        anchors.top: true
        
        // Let Quickshell infer the window boundaries from the pill inside
        // Do NOT use standard anchors.horizontalCenter here
        width: pillContainer.implicitWidth
        height: pillContainer.implicitHeight

        // Prevents the window manager from forcing margins or shrinking spaces
        exclusionMode: ExclusionMode.None 
        color: "transparent"

        // Base structural box to securely handle center alignments
        Item {
            id: pillContainer
            implicitWidth: visualPill.width
            implicitHeight: visualPill.height

            DynamicPill {
                id: visualPill
                
                // Keep the pill floating slightly lower than the absolute screen edge
                anchors.top: parent.top
                anchors.topMargin: 8 
            }
        }
    }
}
