import Quickshell
import Quickshell.Services.Pam
import QtQuick
import qs.common

// The password state every output's lock surface shares, and the PAM
// conversation that checks it.
Scope {
  id: root

  property string password: ""
  property bool checking: false
  property bool failed: false

  signal unlocked

  function submit() {
    if (checking || password === "") return;

    checking = true;
    failed = false;
    pam.start();
  }

  PamContext {
    id: pam

    config: Settings.pamConfig
    configDirectory: Settings.pamDirectory

    onResponseRequiredChanged: {
      if (responseRequired) {
        respond(root.password);
        root.password = "";
      }
    }

    onCompleted: result => {
      root.checking = false;
      if (result === PamResult.Success) {
        root.unlocked();
      } else {
        root.password = "";
        root.failed = true;
      }
    }
  }
}
