{ lib, overrides }:
let
  inherit (lib) mapAttrs mkOption types;

  #
  # App fields, declared once. Catalogue entries set them; overrides
  # replace the fields they define (see overrides.nix), so a nullable
  # field (execFlag, dmenu) can be cleared on purpose.
  #
  appFields = {

    package = {
      type = types.nullOr types.str;
      description = "Package attribute path in pkgs; null when its configure module provides it.";
    };

    command = {
      type = types.listOf types.str;
      description = "Command and arguments that start the app.";
    };

    appId = {
      type = types.str;
      description = "Wayland app id of its windows.";
    };

    inTerminal = {
      type = types.bool;
      description = "Whether the app runs inside the terminal role.";
    };

    execFlag = {
      type = types.nullOr types.str;
      description = "For a terminal: the flag that runs a command in it (e.g. -e).";
    };

    dmenu = {
      type = types.nullOr (types.listOf types.str);
      description = "For a launcher: the command that picks a line from stdin (dmenu mode).";
    };

    desktopEntry = {
      type = types.nullOr types.str;
      description = "Its desktop file, for opening files with it (e.g. firefox.desktop).";
    };

    opensInTerminal = {
      type = types.bool;
      description = "Whether opening a file with it needs a terminal, as xdg-open won't provide one.";
    };

  };

  appDefaults = name: {
    package = name;
    command = [ name ];
    appId = name;
    inTerminal = false;
    execFlag = null;
    dmenu = null;
    desktopEntry = null;
    opensInTerminal = false;
  };

  override = overrides.type appFields;

  applyOverride = overrides.apply appFields;

  # A role resolved: the app's fields, the command already wrapped in the
  # terminal when needed, and what validation needs to know.
  role = types.submodule {
    options = mapAttrs (_: spec: mkOption { inherit (spec) type description; }) appFields // {
      app = mkOption {
        type = types.str;
        description = "Catalogue name of the app playing the role.";
      };

      known = mkOption {
        type = types.bool;
        description = "Whether the app is in the catalogue.";
      };

      fits = mkOption {
        type = types.bool;
        description = "Whether the app can fill this role.";
      };

      packageKnown = mkOption {
        type = types.bool;
        description = "Whether the package exists (true when the configure module provides it).";
      };
    };
  };

  # An app installed without a role: its catalogue fields as they are.
  installed = types.submodule {
    options = mapAttrs (_: spec: mkOption { inherit (spec) type description; }) appFields // {
      app = mkOption {
        type = types.str;
        description = "Catalogue name of the app.";
      };

      known = mkOption {
        type = types.bool;
        description = "Whether the app is in the catalogue.";
      };

      packageKnown = mkOption {
        type = types.bool;
        description = "Whether the package exists (true when the configure module provides it).";
      };
    };
  };

  model = types.submodule {
    options = {

      roles = mkOption {
        type = types.attrsOf role;
        description = "Roles that have an app.";
      };

      installed = mkOption {
        type = types.attrsOf installed;
        description = "Apps installed without a role, by catalogue name.";
      };

      aliases = mkOption {
        type = types.attrsOf types.str;
        description = "Shell aliases of the apps in use (roles and installed).";
      };

      dmenuConsumers = mkOption {
        type = types.listOf types.str;
      };

      defaultHandlers = mkOption {
        type = types.bool;
      };

      handlers = mkOption {
        type = types.attrsOf (types.listOf types.str);
        description = "MIME type -> desktop files, when defaultHandlers is on.";
      };

      handlerEntries = mkOption {
        type = types.attrsOf (types.attrsOf types.anything);
        description = "Generated desktop files for handlers that open in the terminal role.";
      };

      handlersMissing = mkOption {
        type = types.listOf types.str;
        description = "Roles that should handle files but name no desktop file.";
      };

    };
  };
in
{
  inherit
    appFields
    appDefaults
    override
    applyOverride
    role
    installed
    model
    ;
}
