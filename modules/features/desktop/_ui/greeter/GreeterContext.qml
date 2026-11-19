import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick
import qs.common

// The login every output's greeter surface shares: who, which session, the
// password, and the conversation with greetd that checks it and starts the
// session. The last user and session are kept for the next boot.
Scope {
  id: root

  property string password: ""
  property bool checking: false
  property bool failed: false
  property string message: ""

  property var sessions: []
  property int userIndex: 0
  property int sessionIndex: 0

  readonly property var users: Settings.users
  readonly property string user: users[userIndex] ?? ""
  readonly property var session: sessions[sessionIndex] ?? null

  function cycleUser(step) {
    if (checking || users.length < 2) return;
    userIndex = (userIndex + step + users.length) % users.length;
    failed = false;
    message = "";
  }

  function cycleSession(step) {
    if (checking || sessions.length < 2) return;
    sessionIndex = (sessionIndex + step + sessions.length) % sessions.length;
  }

  function submit() {
    if (checking || password === "" || user === "" || session === null) return;

    // Without greetd nothing would ever answer; say so rather than wait.
    if (!Greetd.available) {
      fail("Login service unavailable");
      return;
    }

    checking = true;
    failed = false;
    message = "";
    Greetd.createSession(user);
  }

  function fail(text) {
    if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession();
    password = "";
    checking = false;
    failed = true;
    message = text;
  }

  function remember() {
    last.setText(JSON.stringify({ user: user, session: session.name }));
  }

  function restore(saved) {
    const userAt = users.indexOf(saved.user ?? "");
    if (userAt >= 0) userIndex = userAt;

    const sessionAt = sessions.findIndex(entry => entry.name === saved.session);
    if (sessionAt >= 0) sessionIndex = sessionAt;
  }

  Connections {
    target: Greetd

    function onAuthMessage(text, error, responseRequired, echoResponse) {
      // The password answers the first prompt; any further one (a second
      // factor this greeter can't ask for) gets nothing and fails.
      if (responseRequired) {
        Greetd.respond(root.password);
        root.password = "";
      }
    }

    function onAuthFailure(text) {
      root.fail("Wrong password");
    }

    function onError(text) {
      root.fail(text);
    }

    function onReadyToLaunch() {
      root.remember();

      const environment = ["XDG_SESSION_TYPE=wayland"];
      if (root.session.desktopNames !== "")
        environment.push("XDG_SESSION_DESKTOP=" + root.session.desktopNames.split(";")[0]);

      // The Exec line is run by greetd's shell, so it stays one word.
      Greetd.launch([root.session.exec], environment, true);
    }
  }

  // [{ name, exec, desktopNames }], built from the uwsm session files.
  FileView {
    path: Settings.sessionsFile
    printErrors: false

    onLoaded: {
      try {
        root.sessions = JSON.parse(text());
      } catch (error) {
        root.sessions = [];
      }
      last.reload();
    }
  }

  // Not Quickshell.statePath: that follows the config's store path, which
  // every rebuild changes.
  FileView {
    id: last

    path: Quickshell.env("XDG_STATE_HOME") + "/last.json"
    printErrors: false

    onLoaded: {
      try {
        root.restore(JSON.parse(text()));
      } catch (error) {
        // Nothing worth recovering: the first user and session stay.
      }
    }
  }
}
