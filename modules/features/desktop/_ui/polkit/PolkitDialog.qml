import QtQuick
import qs.common

// The prompt for one polkit request. Leaving it by any route, Escape, a press
// outside or another surface opening, cancels the request, so the application
// waiting on it never hangs. The password only ever lives in the field.
Overlay {
  id: root

  required property var flow
  property bool failed: false

  function reset() {
    field.text = "";
    failed = false;
  }

  function submit() {
    if (!flow?.isResponseRequired || field.text === "") return;

    const password = field.text;
    field.text = "";
    flow.submit(password);
  }

  surface: "polkit"
  scrimmed: true

  onFlowChanged: {
    reset();
    if (flow) field.takeFocus();
  }

  onShownChanged: {
    if (shown) {
      field.takeFocus();
      return;
    }

    reset();
    if (flow && !flow.isCompleted && !flow.isCancelled) flow.cancelAuthenticationRequest();
  }

  Connections {
    target: root.flow
    ignoreUnknownSignals: true

    function onAuthenticationFailed() {
      root.failed = true;
      field.text = "";
      field.shake();
    }
  }

  Panel {
    id: panel

    anchors.centerIn: parent
    implicitWidth: Theme.sizeSidePanel + Theme.spaceXl * 2
    implicitHeight: column.implicitHeight + Theme.spaceXl * 2
    opacity: root.progress
    scale: 0.96 + root.progress * 0.04

    // Presses inside the panel must not reach the overlay's dismiss area.
    MouseArea {
      anchors.fill: parent
    }

    Column {
      id: column

      anchors.centerIn: parent
      width: Theme.sizeSidePanel
      spacing: Theme.spaceMd

      Label {
        width: parent.width
        text: "Authentication required"
        size: Theme.fontHeading
        font.weight: Font.DemiBold
      }

      Label {
        width: parent.width
        text: root.flow?.message ?? ""
        color: Theme.muted
        wrapMode: Text.Wrap
        maximumLineCount: 4
      }

      PasswordField {
        id: field

        width: parent.width
        busy: !(root.flow?.isResponseRequired ?? false)
        failed: root.failed
        reveal: root.flow?.responseVisible ?? false
        placeholder: {
          if (root.failed) return "Wrong password";
          return root.flow?.inputPrompt || "Password";
        }

        onEdited: root.failed = false
        onAccepted: root.submit()
      }

      Label {
        width: parent.width
        visible: text !== ""
        text: root.flow?.supplementaryMessage ?? ""
        color: root.flow?.supplementaryIsError ? Theme.danger : Theme.muted
        size: Theme.fontSmall
        wrapMode: Text.Wrap
      }

      Row {
        anchors.right: parent.right
        spacing: Theme.spaceSm

        Pressable {
          implicitWidth: cancelLabel.implicitWidth + Theme.spaceLg * 2
          implicitHeight: cancelLabel.implicitHeight + Theme.spaceMd
          onClicked: Ui.close()

          Label {
            id: cancelLabel

            anchors.centerIn: parent
            text: "Cancel"
          }
        }

        Pressable {
          id: confirm

          implicitWidth: confirmLabel.implicitWidth + Theme.spaceLg * 2
          implicitHeight: confirmLabel.implicitHeight + Theme.spaceMd
          selected: true
          onClicked: root.submit()

          Label {
            id: confirmLabel

            anchors.centerIn: parent
            text: "Authenticate"
            color: confirm.foreground
          }
        }
      }
    }
  }
}
