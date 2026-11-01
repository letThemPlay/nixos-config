{ lib, desktop }:
let
  inherit (lib)
    attrNames
    attrValues
    concatLists
    filter
    filterAttrs
    genAttrs
    mapAttrs
    unique
    ;

in

#
# cfg is the ltp.desktop option set, or any attrset of the same shape.
# hasPackage tells whether a pkgs attribute path exists, and keyboard
# is the session keyboard ({ layout; variant; }, from ltp.locale), and
# facts the host's hardware facts (ltp.hardware.facts; null: unknown,
# nothing is filtered); the desktop module supplies them. No module
# system is required.
#
{
  cfg,
  hasPackage ? _: true,
  keyboard ? {
    layout = "gb";
    variant = "";
  },
  facts ? null,
}:

let
  # appDefaults <- default role <- override.
  roles = genAttrs (unique (attrNames desktop.defaultApps ++ attrNames cfg.apps)) (
    role:
    desktop.types.applyAppOverride (
      desktop.types.appDefaults role // (desktop.defaultApps.${role} or { })
    ) (cfg.apps.${role} or { })
  );

  terminal = roles.terminal or null;

  # Apps that run in a terminal are started through the terminal role.
  apps = mapAttrs (
    _: app:
    app
    // {
      known = hasPackage app.package;

      command =
        if app.inTerminal && terminal != null && terminal.execFlag != null then
          terminal.command ++ [ terminal.execFlag ] ++ app.command
        else
          app.command;
    }
  ) roles;

  # Plain-data binds get the bind type's full shape.
  shape =
    bind:
    {
      spawn = null;
      action = null;
      app = null;
      requires = [ ];
    }
    // bind;

  # Whether the host has every hardware fact in a requirement list.
  met = requires: facts == null || builtins.all (fact: facts.${fact} or false) requires;

  barRequires = cfg.bar.requires or { };

  keepWidget = widget: met (barRequires.${widget} or [ ]);

  merged = mapAttrs (_: shape) (
    (if cfg.defaultBinds then desktop.defaultBinds else { }) // cfg.binds
  );

  # Plain-data rules get the rule type's full shape.
  ruleShape =
    rule:
    {
      opacity = null;
      shadow = null;
      focusRing = null;
      floating = null;
    }
    // rule
    // {
      match = {
        appId = null;
        isActive = null;
      }
      // (rule.match or { });
    };
in
{
  compositors = map (name: {
    inherit name;
    known = desktop.compositors ? ${name};
  }) cfg.compositors;

  inherit apps;

  # A component or host rule replaces the default with the same name.
  windowRules = mapAttrs (_: ruleShape) (
    (if cfg.defaultWindowRules then desktop.defaultWindowRules else { }) // cfg.windowRules
  );

  # A component or host bind replaces the default for its key; command
  # is the final argv of a spawn or app bind.
  binds = mapAttrs (
    _: bind:
    bind
    // {
      command =
        if bind.spawn != null then
          bind.spawn
        else if bind.app != null && apps ? ${bind.app} then
          apps.${bind.app}.command
        else
          null;
    }
  ) (filterAttrs (_: bind: met bind.requires) merged);

  # Binds left out for missing hardware are reported; widgets just go.
  requirements = {
    known = if facts == null then null else attrNames facts;

    used = unique (
      concatLists (map (bind: bind.requires) (attrValues merged)) ++ concatLists (attrValues barRequires)
    );

    droppedBinds = mapAttrs (_: bind: bind.requires) (
      filterAttrs (_: bind: !(met bind.requires)) merged
    );
  };

  bar = cfg.bar // {
    left = filter keepWidget cfg.bar.left;
    center = filter keepWidget cfg.bar.center;
    right = filter keepWidget cfg.bar.right;
  };

  inherit keyboard;

  greeter = {
    name = cfg.greeter;
    known = cfg.greeter == null || desktop.greeters ? ${cfg.greeter};
  };

  inherit (cfg)
    services
    idle
    ;
}
