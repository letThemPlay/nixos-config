{ lib }:

#
# The generated QML of the unified shell, as text. Theme.qml carries one
# user's resolved tokens and Settings.qml what the model selected; every
# hand-written surface in _ui reads only these two, so a look or layout
# change never touches a surface.
#
let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    ;

  quoted = builtins.toJSON;

  property =
    type: name: value:
    "  readonly property ${type} ${name}: ${value}";

  singleton = lines: ''
    pragma Singleton

    import Quickshell
    import QtQuick

    Singleton {
    ${concatStringsSep "\n" lines}
    }
  '';

  capitalize =
    text:
    lib.toUpper (builtins.substring 0 1 text) + builtins.substring 1 (builtins.stringLength text) text;

  # { xs = 4; } under "space" -> spaceXs.
  scale =
    type: prefix: values:
    mapAttrsToList (name: value: property type "${prefix}${capitalize name}" (toString value)) values;
in
{
  #
  # tokens is ltp.theme.facts.ui; colors the user's base16 scheme (slot ->
  # bare hex, as stylix provides).
  #
  theme =
    { tokens, colors }:
    singleton (
      mapAttrsToList (role: slot: property "color" role (quoted "#${colors.${slot}}")) tokens.palette
      ++ [
        (property "color" "panel" "Qt.alpha(surface, ${toString tokens.opacity.panel})")
        (property "color" "scrim" "Qt.alpha(background, ${toString tokens.opacity.scrim})")
        # Black rather than a scheme colour, as a shadow reads as one on light schemes too.
        (property "color" "shadow" "Qt.alpha(\"#000000\", ${toString tokens.opacity.shadow})")
        (property "string" "fontFamily" (quoted tokens.font.family))
        (property "string" "fontMonospace" (quoted tokens.font.monospace))
        (property "string" "iconFont" (quoted tokens.icon.name))
      ]
      ++ scale "int" "space" tokens.space
      ++ scale "int" "radius" tokens.radius
      ++ scale "int" "shadow" tokens.shadow
      ++ scale "int" "size" tokens.size
      ++ scale "int" "font" (
        removeAttrs tokens.font [
          "family"
          "monospace"
        ]
      )
      ++ scale "int" "icon" (
        removeAttrs tokens.icon [
          "package"
          "name"
          "theme"
        ]
      )
      ++ scale "int" "motion" tokens.motion
    );

  #
  # The model's choices for one user. A JSON value is a JavaScript value,
  # so structured settings need no separate QML form.
  #
  settings =
    {
      model,
      spawnPrefix,
      pam,
      wallpaper,
      terminal,
    }:
    singleton [
      (property "var" "surfaces" (quoted model.ui.surfaces))
      (property "var" "barLeft" (quoted model.bar.left))
      (property "var" "barCenter" (quoted model.bar.center))
      (property "var" "barRight" (quoted model.bar.right))
      (property "var" "commands" (quoted model.ui.commands))
      (property "var" "powerActions" (
        quoted (mapAttrsToList (id: action: action // { inherit id; }) model.ui.powerActions)
      ))
      (property "bool" "powerProfiles" (quoted model.ui.powerProfiles))
      (property "var" "batteryLevels" (quoted model.ui.batteryLevels))
      (property "var" "notificationHistory" (quoted model.notificationHistory))
      (property "var" "dockApps" (quoted model.dockApps))
      (property "var" "nightLight" (quoted model.nightLight))
      (property "var" "spawnPrefix" (quoted spawnPrefix))
      (property "var" "terminal" (quoted terminal))
      (property "string" "pamConfig" (quoted pam.config))
      (property "string" "pamDirectory" (quoted pam.directory))
      (property "string" "wallpaper" (quoted wallpaper))
    ];
}
