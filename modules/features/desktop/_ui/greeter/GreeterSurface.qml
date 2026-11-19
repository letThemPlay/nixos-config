import Quickshell
import QtQuick
import qs.common

// One output's login: the lock screen's clock and password field over the
// same backdrop, with who logs in above the field, the session below it
// when there's a choice, and the power actions in the corner. Up and Down
// change the user, Tab the session.
Backdrop {
  id: root

  required property var greeter

  property string pending: ""

  readonly property var order: ["suspend", "reboot", "poweroff"]

  function power(action) {
    if (action.confirm && pending !== action.id) {
      pending = action.id;
      return;
    }

    pending = "";
    Quickshell.execDetached(action.command);
  }

  Column {
    anchors.centerIn: parent
    spacing: Theme.spaceXl

    BigClock {
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Theme.spaceMd

      // Who logs in; arrows only when there is more than one user.
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spaceSm

        IconButton {
          anchors.verticalCenter: parent.verticalCenter
          icon: "previous"
          visible: root.greeter.users.length > 1
          onClicked: root.greeter.cycleUser(-1)
        }

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Theme.spaceSm

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "user"
            size: Theme.iconMedium
          }

          Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.greeter.user
            size: Theme.fontHeading
          }
        }

        IconButton {
          anchors.verticalCenter: parent.verticalCenter
          icon: "more"
          visible: root.greeter.users.length > 1
          onClicked: root.greeter.cycleUser(1)
        }
      }

      PasswordField {
        id: field

        anchors.horizontalCenter: parent.horizontalCenter
        text: root.greeter.password
        busy: root.greeter.checking
        failed: root.greeter.failed
        placeholder: {
          if (root.greeter.checking) return "Logging in";
          return root.greeter.failed ? root.greeter.message : "Password";
        }

        onEdited: root.greeter.password = text
        onAccepted: root.greeter.submit()
        Component.onCompleted: takeFocus()

        Keys.onUpPressed: root.greeter.cycleUser(-1)
        Keys.onDownPressed: root.greeter.cycleUser(1)
        Keys.onTabPressed: root.greeter.cycleSession(1)
        Keys.onBacktabPressed: root.greeter.cycleSession(-1)

        Connections {
          target: root.greeter

          function onFailedChanged() {
            if (root.greeter.failed) field.shake();
          }
        }
      }

      // The session, only when there is a choice.
      Pressable {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.greeter.sessions.length > 1
        implicitWidth: sessionRow.implicitWidth + Theme.spaceMd * 2
        implicitHeight: sessionRow.implicitHeight + Theme.spaceSm * 2

        onClicked: button => root.greeter.cycleSession(button === Qt.RightButton ? -1 : 1)

        Row {
          id: sessionRow

          anchors.centerIn: parent
          spacing: Theme.spaceSm

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "session"
            size: Theme.iconSmall
            color: Theme.muted
          }

          Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.greeter.session?.name ?? ""
            color: Theme.muted
          }
        }
      }
    }
  }

  // Power actions; ending anything asks a second time, as in the power menu.
  Panel {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Theme.spaceXl
    implicitWidth: actions.implicitWidth + Theme.spaceSm * 2
    implicitHeight: actions.implicitHeight + Theme.spaceSm * 2

    Row {
      id: actions

      anchors.centerIn: parent
      spacing: Theme.spaceXs

      Repeater {
        model: Settings.powerActions
          .slice()
          .sort((a, b) => root.order.indexOf(a.id) - root.order.indexOf(b.id))

        IconButton {
          required property var modelData

          icon: modelData.icon
          iconSize: Theme.iconMedium
          danger: root.pending === modelData.id

          onClicked: root.power(modelData)
          onHoveredChanged: {
            if (!hovered && root.pending === modelData.id) root.pending = "";
          }
        }
      }
    }
  }
}
