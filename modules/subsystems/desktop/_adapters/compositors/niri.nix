{ lib }:
let
  inherit (lib)
    concatMapStringsSep
    escape
    mapAttrsToList
    filterAttrs
    ;

  kdlString = value: "\"${escape [ "\\" "\"" ] value}\"";

  kdlArgs = concatMapStringsSep " " kdlString;
in
rec {

  session = "niri";

  configFile = "niri/config.kdl";

  # Vocabulary -> niri bind action.
  actions = {
    close = "close-window";
    quit = "quit";

    focus-left = "focus-column-left";
    focus-right = "focus-column-right";
    focus-up = "focus-window-or-workspace-up";
    focus-down = "focus-window-or-workspace-down";

    move-left = "move-column-left";
    move-right = "move-column-right";
    move-up = "move-window-up";
    move-down = "move-window-down";

    maximize = "maximize-column";
    fullscreen = "fullscreen-window";
    center = "center-column";

    consume = "consume-window-into-column";
    expel = "expel-window-from-column";
    cycle-width = "switch-preset-column-width";
    grow = ''set-column-width "+10%"'';
    shrink = ''set-column-width "-10%"'';
  };

  # Abstract bar widgets -> waybar modules.
  widgets = {
    workspaces = "niri/workspaces";
  };

  # System pieces, as names; the desktop module maps them to NixOS.
  system = {
    package = "niri";
    portals = [ "xdg-desktop-portal-gnome" ];
    keyring = true;
  };

  render =
    { model, spawnPrefix }:
    let
      bindAction =
        bind:
        if bind.command != null then
          "spawn ${kdlArgs (spawnPrefix ++ bind.command)};"
        else
          "${actions.${bind.action}};";

      # Unsupported actions are reported by validation; leave them out.
      binds = filterAttrs (
        _: bind: bind.command != null || (bind.action != null && actions ? ${bind.action})
      ) model.binds;
    in
    ''
      input {
          keyboard {
              xkb {
                  layout ${kdlString model.keyboard.layout}
              }
          }
          touchpad {
              tap
              dwt
          }
      }

      layout {
          gaps 12
          default-column-width { proportion 0.5; }
          struts {
              top 4
          }

          focus-ring {
              off
          }

          shadow {
              off
          }
      }

      window-rule {
          match is-active=true
          opacity 1.0
      }

      window-rule {
          match is-active=false
          opacity 0.85
      }

      window-rule {
          match app-id="^fuzzel$"

          // Soft floating shadow for the launcher.
          shadow {
              on;
              softness 16;
              color "rgba(0, 0, 0, 0.65)";
              offset x=10 y=10;
          }

          focus-ring { on; }
      }

      // Export NIRI_SOCKET to the systemd user session (waybar's
      // niri/workspaces needs it).
      spawn-at-startup "uwsm" "finalize" "NIRI_SOCKET"

      binds {
      ${concatMapStringsSep "\n" (line: "    ${line}") (
        mapAttrsToList (key: bind: "${kdlString key} { ${bindAction bind} }") binds
      )}
      }
    '';

}
