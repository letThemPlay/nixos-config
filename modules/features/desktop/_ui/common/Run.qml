pragma Singleton

import Quickshell
import QtQuick

// Starts things for the surfaces. Applications run as session applications,
// so restarting the shell never takes them down with it.
Singleton {
  function app(argv) {
    Quickshell.execDetached(Settings.spawnPrefix.concat(argv));
  }

  function inTerminal(argv) {
    app(Settings.terminal.concat(argv));
  }

  function command(name, args) {
    const argv = Settings.commands[name];
    if (argv) Quickshell.execDetached(argv.concat(args ?? []));
  }

  function has(name) {
    return Settings.commands[name] !== undefined;
  }
}
