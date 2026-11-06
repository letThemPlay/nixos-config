import QtQuick

// The field every password is typed into: the lock screen and polkit prompts.
// A surface owns what the text means and when it is cleared.
Panel {
  id: root

  // It sits in a panel or on the lock screen's own backdrop.
  elevated: false

  property alias text: input.text
  property string placeholder: "Password"
  property bool failed: false
  property bool busy: false
  property bool reveal: false
  property real offset: 0

  signal edited
  signal accepted

  function takeFocus() {
    input.forceActiveFocus();
  }

  function shake() {
    shaking.restart();
  }

  implicitWidth: Theme.sizeSidePanel
  implicitHeight: Theme.sizeField
  border.width: 2
  border.color: {
    if (failed) return Theme.danger;
    return input.activeFocus ? Theme.accent : Qt.alpha(Theme.outline, 0.5);
  }

  transform: Translate {
    x: root.offset
  }

  SequentialAnimation {
    id: shaking

    NumberAnimation { target: root; property: "offset"; to: -Theme.spaceSm; duration: Theme.motionFast / 2 }
    NumberAnimation { target: root; property: "offset"; to: Theme.spaceSm; duration: Theme.motionFast / 2 }
    NumberAnimation { target: root; property: "offset"; to: 0; duration: Theme.motionFast / 2 }
  }

  Icon {
    id: icon

    anchors.left: parent.left
    anchors.leftMargin: Theme.spaceLg
    anchors.verticalCenter: parent.verticalCenter
    name: "lock"
    size: Theme.iconMedium
    color: Theme.muted
  }

  TextInput {
    id: input

    anchors.left: icon.right
    anchors.right: parent.right
    anchors.leftMargin: Theme.spaceMd
    anchors.rightMargin: Theme.spaceLg
    anchors.verticalCenter: parent.verticalCenter

    focus: true
    enabled: !root.busy
    echoMode: root.reveal ? TextInput.Normal : TextInput.Password
    passwordCharacter: "•"
    inputMethodHints: Qt.ImhSensitiveData
    color: Theme.text
    selectionColor: Theme.accent
    selectedTextColor: Theme.accentText
    font.family: Theme.fontFamily
    font.pointSize: Theme.fontTitle

    onTextEdited: root.edited()
    onAccepted: root.accepted()

    Label {
      anchors.fill: parent
      visible: input.text === ""
      text: root.placeholder
      size: Theme.fontTitle
      color: root.failed ? Theme.danger : Theme.muted
    }
  }
}
