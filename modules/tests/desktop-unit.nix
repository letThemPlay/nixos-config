{ config, lib, ... }:
let
  desktop = config.flake.subsystems.desktop;

  inherit (config.flake.nixosModules) desktop-api;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        desktop-api
        { ltp.desktop = settings; }
      ];
    }).config.ltp.desktop;

  modelOf = settings: desktop.normalize { cfg = evalCfg settings; };

  codesOf = validate: model: lib.sort lib.lessThan (map (d: d.code) (validate.all model).diagnostics);

  codes = settings: codesOf desktop.validate (modelOf settings);

  niriOf =
    settings:
    desktop.compositors.niri.render {
      model = modelOf settings;
      inherit (desktop) spawnPrefix;
    };

  hasLine = text: line: lib.hasInfix line text;

  # A registry with a compositor that maps nothing, for the
  # compositor-dependent checks.
  bare = desktop // {
    compositors = desktop.compositors // {
      bare = {
        actions = { };
        widgets = { };
      };
    };
  };

  bareValidate = import ../subsystems/desktop/_usecases/validate.nix {
    inherit lib;
    desktop = bare;
    inherit (config.flake.subsystems) diagnostics;
  };

  onBare =
    settings:
    (modelOf settings)
    // {
      compositors = [
        {
          name = "bare";
          known = true;
        }
      ];
    };

  contractCases = [
    { }
    {
      binds."Mod+Return".spawn = [ "alacritty" ];
      bar.left = [ "workspaces" ];
      services.dock = {
        description = "Dock";
        exec = [ "waybar" ];
        compositors = [ "niri" ];
      };
    }
    { defaultBinds = false; }
  ];

  tests = {

    testDefaultsAreValid = {
      expr = codes { };
      expected = [ ];
    };

    testDefaultBindsRenderToNiri = {
      expr = map (hasLine (niriOf { })) [
        ''"Mod+Q" { close-window; }''
        ''"Mod+Left" { focus-column-left; }''
        ''"Mod+Up" { focus-window-or-workspace-up; }''
        ''"Mod+Minus" { set-column-width "-10%"; }''
        ''"Mod+Shift+E" { quit; }''
      ];
      expected = [
        true
        true
        true
        true
        true
      ];
    };

    testSpawnIsSessionApp = {
      expr = hasLine (niriOf {
        binds."Mod+Return".spawn = [ "alacritty" ];
      }) ''"Mod+Return" { spawn "uwsm" "app" "--" "alacritty"; }'';
      expected = true;
    };

    testKeyboardLayout = {
      expr = hasLine (niriOf { keyboard.layout = "us"; }) ''layout "us"'';
      expected = true;
    };

    testComponentBindReplacesDefault = {
      expr = (modelOf { binds."Mod+Q".spawn = [ "foo" ]; }).binds."Mod+Q";
      expected = {
        spawn = [ "foo" ];
        action = null;
        app = null;
        command = [ "foo" ];
      };
    };

    testDefaultBindsOff = {
      expr = (modelOf { defaultBinds = false; }).binds;
      expected = { };
    };

    testInvalidBind = {
      expr = map codes [
        { binds."Mod+X".spawn = [ ]; }
        {
          binds."Mod+X" = {
            spawn = [ "a" ];
            action = "close";
          };
        }
      ];
      expected = [
        [ "desktop.bind.invalid" ]
        [ "desktop.bind.invalid" ]
      ];
    };

    testTerminalRoleBind = {
      expr = hasLine (niriOf { }) ''"Mod+Return" { spawn "uwsm" "app" "--" "alacritty"; }'';
      expected = true;
    };

    testInTerminalAppRunsInTerminal = {
      expr = (modelOf { }).apps.fileManager.command;
      expected = [
        "alacritty"
        "-e"
        "yazi"
      ];
    };

    testRoleOverrideKeepsOtherFields = {
      expr =
        let
          browser =
            (modelOf {
              apps.browser.command = [
                "firefox"
                "--new-window"
              ];
            }).apps.browser;
        in
        {
          inherit (browser) package appId command;
        };
      expected = {
        package = "firefox";
        appId = "firefox";
        command = [
          "firefox"
          "--new-window"
        ];
      };
    };

    testAppBindUsesRole = {
      expr = (modelOf { binds."Mod+B".app = "browser"; }).binds."Mod+B".command;
      expected = [ "firefox" ];
    };

    testUnknownAppRole = {
      expr = codes { binds."Mod+B".app = "editor2"; };
      expected = [ "desktop.bind.app.unknown" ];
    };

    testUnknownPackage = {
      expr = codesOf desktop.validate (
        desktop.normalize {
          cfg = evalCfg { };
          hasPackage = path: path != "yazi";
        }
      );
      expected = [ "desktop.app.package.unknown" ];
    };

    # An override cannot unset execFlag (null means "not set"), so the
    # model is edited directly.
    testTerminalWithoutExecFlag = {
      expr =
        let
          model = modelOf { };
        in
        codesOf desktop.validate (
          model
          // {
            apps = model.apps // {
              terminal = model.apps.terminal // {
                execFlag = null;
              };
            };
          }
        );
      expected = [ "desktop.app.terminal.missing" ];
    };

    testUnknownCompositor = {
      expr = map codes [
        { compositors = [ "sway" ]; }
        { compositors = [ ]; }
      ];
      expected = [
        [ "desktop.compositor.unknown" ]
        [ "desktop.compositors.none" ]
      ];
    };

    testUnsupportedAction = {
      expr = lib.unique (
        codesOf bareValidate (onBare {
          defaultWindowRules = false;
        })
      );
      expected = [ "desktop.bind.unsupported" ];
    };

    testUnsupportedWidget = {
      expr = codesOf bareValidate (onBare {
        defaultBinds = false;
        defaultWindowRules = false;
        bar.left = [
          "clock"
          "workspaces"
        ];
      });
      expected = [ "desktop.bar.widget.unsupported" ];
    };

    testDefaultRulesRender = {
      expr = map (hasLine (niriOf { })) [
        "window-rule {\n    match is-active=true\n    opacity 1.0\n}"
        "window-rule {\n    match is-active=false\n    opacity 0.85\n}"
      ];
      expected = [
        true
        true
      ];
    };

    testComponentRuleRenders = {
      expr =
        let
          text = niriOf {
            windowRules.launcher = {
              match.appId = "^launcher$";
              shadow = {
                softness = 16;
                color = "rgba(0, 0, 0, 0.65)";
                offset = {
                  x = 10;
                  y = 10;
                };
              };
              focusRing = true;
              floating = true;
            };
          };
        in
        map (hasLine text) [
          "match app-id=\"^launcher$\""
          "        offset x=10 y=10;"
          "    focus-ring { on; }"
          "    open-floating true"
        ];
      expected = [
        true
        true
        true
        true
      ];
    };

    testRuleMatchEmpty = {
      expr = codes { windowRules.nothing.opacity = 0.5; };
      expected = [ "desktop.rule.match.empty" ];
    };

    testRuleUnsupported = {
      expr = lib.unique (
        codesOf bareValidate (onBare {
          defaultBinds = false;
        })
      );
      expected = [ "desktop.rule.unsupported" ];
    };

    testWaybarResolvesWidgets = {
      expr = desktop.waybar {
        model = modelOf {
          bar = {
            left = [
              "clock"
              "workspaces"
            ];
            settings = {
              layer = "top";
              workspaces.format = "{index}";
            };
          };
        };
        compositor = desktop.compositors.niri;
      };
      expected = {
        layer = "top";
        "niri/workspaces".format = "{index}";
        modules-left = [
          "clock"
          "niri/workspaces"
        ];
        modules-center = [ ];
        modules-right = [ ];
      };
    };

    testServiceUnits = {
      expr =
        let
          inherit
            (desktop.services {
              model = modelOf {
                services = {
                  any = {
                    description = "Any";
                    exec = [ "a" ];
                  };
                  niriOnly = {
                    description = "Niri";
                    exec = [ "b" ];
                    compositors = [ "niri" ];
                  };
                };
              };
            })
            units
            ;
        in
        {
          any = units.any.Unit ? ConditionEnvironment;
          niri = units.niriOnly.Unit.ConditionEnvironment;
          wanted = units.any.Install.WantedBy;
        };
      expected = {
        any = false;
        niri = [ "|XDG_CURRENT_DESKTOP=niri" ];
        wanted = [ "graphical-session.target" ];
      };
    };

    testModelContract = {
      expr = map (
        settings:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = desktop.types.model; }; }
                { model = modelOf settings; }
              ];
            }).config.model;
        in
        builtins.deepSeq (removeAttrs checked [ "services" ]) true
      ) contractCases;
      expected = map (_: true) contractCases;
    };

  };
in
{
  perSystem =
    { pkgs, ... }:
    let
      failures = lib.runTests tests;
    in
    {
      checks.desktop-unit =
        if failures == [ ] then
          pkgs.runCommand "desktop-unit-tests" { } "touch $out"
        else
          throw "desktop unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
