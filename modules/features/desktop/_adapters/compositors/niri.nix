{ lib }:
let
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    escape
    mapAttrsToList
    filterAttrs
    ;

  kdlString = value: "\"${escape [ "\\" "\"" ] value}\"";

  kdlArgs = concatMapStringsSep " " kdlString;

  session = "niri";

  configFile = "niri/config.kdl";

  # Workspaces by number: focus-workspace-1 -> focus-workspace 1.
  numbered =
    action: native:
    lib.listToAttrs (
      builtins.genList (
        index: lib.nameValuePair "${action}-${toString (index + 1)}" "${native} ${toString (index + 1)}"
      ) 9
    );

  # Vocabulary -> niri bind action.
  actions =
    numbered "focus-workspace" "focus-workspace"
    // numbered "move-to-workspace" "move-column-to-workspace"
    // {
      close = "close-window";
      quit = "quit";

      focus-monitor-left = "focus-monitor-left";
      focus-monitor-right = "focus-monitor-right";
      move-to-monitor-left = "move-column-to-monitor-left";
      move-to-monitor-right = "move-column-to-monitor-right";

      focus-workspace-up = "focus-workspace-up";
      focus-workspace-down = "focus-workspace-down";
      move-to-workspace-up = "move-column-to-workspace-up";
      move-to-workspace-down = "move-column-to-workspace-down";

      # Both save to ~/Pictures/Screenshots and copy to the clipboard.
      screenshot-screen = "screenshot-screen";
      screenshot-window = "screenshot-window";

      overview = "toggle-overview";
      toggle-floating = "toggle-window-floating";
      focus-floating = "switch-focus-between-floating-and-tiling";
      show-hotkeys = "show-hotkey-overlay";

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

  # Window rule properties niri renders.
  ruleProperties = [
    "opacity"
    "shadow"
    "focusRing"
    "floating"
  ];

  #
  # The uwsm-managed session (programs.uwsm.waylandCompositors). niri's
  # own niri.service runs `niri --session`; under uwsm it runs as a
  # systemd user unit the same way.
  #
  uwsm = {
    prettyName = "Niri";
    comment = "Niri, managed by uwsm";
    binPath = "/run/current-system/sw/bin/niri";
    extraArgs = [ "--session" ];
  };

  # System pieces, as names; the desktop module maps them to NixOS.
  system = {
    package = "niri";
    portals = [ "xdg-desktop-portal-gnome" ];
    keyring = true;

    # niri has no X server of its own: it starts xwayland-satellite on
    # demand and only sets DISPLAY when it finds it on PATH.
    packages = [ "xwayland-satellite" ];
  };

  render =
    { model, spawnPrefix }:
    let
      bindAction =
        bind:
        if bind.command != null then
          "spawn ${kdlArgs ((if bind.direct then [ ] else spawnPrefix) ++ bind.command)};"
        else
          "${actions.${bind.action}};";

      # 0.85, not Nix's 0.850000.
      number =
        value:
        let
          text = toString value;
          trimmed = builtins.match "(-?[0-9]+\\.[0-9]*[1-9])0*" text;
          whole = builtins.match "(-?[0-9]+)\\.0*" text;
        in
        if trimmed != null then
          builtins.head trimmed
        else if whole != null then
          "${builtins.head whole}.0"
        else
          text;

      onOff = enabled: if enabled then "on" else "off";

      ruleMatch =
        match:
        concatStringsSep " " (
          lib.optional (match.appId != null) "app-id=${kdlString match.appId}"
          ++ lib.optional (match.isActive != null) "is-active=${lib.boolToString match.isActive}"
        );

      #
      # Unsupported properties are reported by validation; niri renders
      # every property a rule can set.
      #
      renderRule =
        rule:
        concatStringsSep "\n" (
          [
            "window-rule {"
            "    match ${ruleMatch rule.match}"
          ]
          ++ lib.optional (rule.opacity != null) "    opacity ${number rule.opacity}"
          ++ lib.optionals (rule.shadow != null) [
            "    shadow {"
            "        on;"
            "        softness ${toString rule.shadow.softness};"
            "        color ${kdlString rule.shadow.color};"
            "        offset x=${toString rule.shadow.offset.x} y=${toString rule.shadow.offset.y};"
            "    }"
          ]
          ++ lib.optional (rule.focusRing != null) "    focus-ring { ${onOff rule.focusRing}; }"
          ++ lib.optional (rule.floating != null) "    open-floating ${lib.boolToString rule.floating}"
          ++ [ "}" ]
        );

      # Unsupported actions are reported by validation; leave them out.
      binds = filterAttrs (
        _: bind: bind.command != null || (bind.action != null && actions ? ${bind.action})
      ) model.binds;
    in
    ''
      // Its spawn entries are raw store paths: useful on demand, not at login.
      hotkey-overlay {
          skip-at-startup
      }

      input {
          keyboard {
              xkb {
                  layout ${kdlString model.keyboard.layout}${
                    lib.optionalString (
                      model.keyboard.variant != ""
                    ) "\n            variant ${kdlString model.keyboard.variant}"
                  }
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

      ${concatStringsSep "\n\n" (map renderRule (builtins.attrValues model.windowRules))}

      // Export NIRI_SOCKET to the systemd user session (waybar's
      // niri/workspaces needs it).
      spawn-at-startup "uwsm" "finalize" "NIRI_SOCKET"

      binds {
      ${concatMapStringsSep "\n" (line: "    ${line}") (
        mapAttrsToList (key: bind: "${kdlString key} { ${bindAction bind} }") binds
      )}
      }
    '';
in
{
  inherit
    session
    configFile
    actions
    widgets
    ruleProperties
    uwsm
    system
    render
    ;
}
