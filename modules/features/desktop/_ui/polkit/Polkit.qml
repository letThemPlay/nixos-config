import Quickshell
import Quickshell.Services.Polkit
import QtQuick
import qs.common

// The session's polkit agent. The dialog is open exactly while a request is
// active: the agent moves straight on to the next queued one, so following the
// flow keeps a finishing request from closing the prompt of the next.
Scope {
  PolkitAgent {
    id: agent

    onFlowChanged: {
      if (flow) Ui.open = "polkit";
      else if (Ui.open === "polkit") Ui.close();
    }
  }

  PolkitDialog {
    flow: agent.flow
  }
}
