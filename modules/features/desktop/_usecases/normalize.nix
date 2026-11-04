{ lib, desktop }:
let
  inherit (lib)
    attrNames
    attrValues
    concatLists
    filter
    filterAttrs
    mapAttrs
    unique
    ;

in

#
# cfg is the ltp.desktop option set, or any attrset of the same shape.
# apps are the resolved app roles (ltp.apps.facts) that app binds start,
# keyboard is the session keyboard ({ layout; variant; }, from ltp.locale), and
# facts the host's hardware facts (ltp.hardware.facts; null: unknown,
# nothing is filtered); the desktop module supplies them. No module
# system is required.
#
{
  cfg,
  apps ? { },
  keyboard ? {
    layout = "gb";
    variant = "";
  },
  facts ? null,
}:

let
  # Plain-data binds get the bind type's full shape.
  shape =
    bind:
    {
      spawn = null;
      action = null;
      app = null;
      requires = [ ];
      direct = false;
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

  # A component or host rule replaces the default with the same name.
  windowRules = mapAttrs (_: ruleShape) (
    (if cfg.defaultWindowRules then desktop.defaultWindowRules else { }) // cfg.windowRules
  );

  appRoles = attrNames apps;

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

  components = mapAttrs (role: name: {
    inherit name;
    known = name == null || (desktop.components.${role} or { }) ? ${name};
  }) cfg.components;

  greeter = {
    name = cfg.greeter;
    known = cfg.greeter == null || desktop.greeters ? ${cfg.greeter};
  };

  displays = cfg.displays or { profiles = { }; };

  # The roles that selected the unified shell are the surfaces it draws.
  ui = {
    surfaces = attrNames (filterAttrs (_: name: name == desktop.uiComponent) cfg.components);

    commands = cfg.ui.commands or { };

    inherit (desktop) powerActions;

    powerProfiles = if facts == null then false else facts.powerProfiles or false;

    # The hardware feature's defaults, for a host that publishes none.
    batteryLevels =
      if facts == null then
        {
          low = 20;
          critical = 5;
        }
      else
        facts.batteryLevels or {
          low = 20;
          critical = 5;
        };
  };

  inherit (cfg)
    services
    idle
    ;
}
