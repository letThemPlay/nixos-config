import QtQuick
import qs.common

// One output's lock screen: the clock and the password field over the
// shared backdrop.
Backdrop {
  id: root

  required property var context

  Column {
    anchors.centerIn: parent
    spacing: Theme.spaceXl

    BigClock {
      anchors.horizontalCenter: parent.horizontalCenter
    }

    PasswordField {
      id: field

      anchors.horizontalCenter: parent.horizontalCenter
      text: root.context.password
      busy: root.context.checking
      failed: root.context.failed
      placeholder: {
        if (root.context.checking) return "Checking";
        return root.context.failed ? "Wrong password" : "Password";
      }

      onEdited: root.context.password = text
      onAccepted: root.context.submit()
      Component.onCompleted: takeFocus()

      Connections {
        target: root.context

        function onFailedChanged() {
          if (root.context.failed) field.shake();
        }
      }
    }
  }
}
