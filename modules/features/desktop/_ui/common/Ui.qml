pragma Singleton

import Quickshell
import QtQuick

// Which transient surface is open. At most one is: opening one replaces
// the other, as they would otherwise fight over the keyboard.
Singleton {
  property string open: ""

  function toggle(surface) {
    open = open === surface ? "" : surface;
  }

  function close() {
    open = "";
  }
}
