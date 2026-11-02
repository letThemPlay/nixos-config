{ config, lib, ... }:
let
  desktop = config.ltp.features.desktop;

  inherit (config.flake.nixosModules) desktop-options;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        desktop-options
        { ltp.desktop = settings; }
      ];
    }).config.ltp.desktop;

  # App roles as the apps feature would publish them.
  appFacts = {
    terminal.command = [ "alacritty" ];
    launcher.command = [ "fuzzel" ];
    browser.command = [ "firefox" ];
  };

  normalizeWith = args: desktop.normalize ({ apps = appFacts; } // args);

  modelOf = settings: normalizeWith { cfg = evalCfg settings; };

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

  bareValidate = import ../features/desktop/_usecases/validate.nix {
    inherit lib;
    desktop = bare;
    inherit (config.ltp.features) diagnostics;
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

    # The session keyboard comes from ltp.locale as an input.
    testKeyboardLayout =
      let
        render =
          keyboard:
          desktop.compositors.niri.render {
            model = normalizeWith {
              cfg = evalCfg { };
              inherit keyboard;
            };
            inherit (desktop) spawnPrefix;
          };

        plain = render {
          layout = "us";
          variant = "";
        };

        withVariant = render {
          layout = "gb";
          variant = "extd";
        };
      in
      {
        expr = {
          layout = hasLine plain ''layout "us"'';
          noVariant = hasLine plain "variant";
          variant = hasLine withVariant "layout \"gb\"\n            variant \"extd\"";
        };
        expected = {
          layout = true;
          noVariant = false;
          variant = true;
        };
      };

    testComponentBindReplacesDefault = {
      expr = (modelOf { binds."Mod+Q".spawn = [ "foo" ]; }).binds."Mod+Q";
      expected = {
        spawn = [ "foo" ];
        action = null;
        app = null;
        requires = [ ];
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

    testAppBindUsesRole = {
      expr = (modelOf { binds."Mod+B".app = "browser"; }).binds."Mod+B".command;
      expected = [ "firefox" ];
    };

    testUnknownAppRole = {
      expr = codes { binds."Mod+B".app = "editor2"; };
      expected = [ "desktop.bind.app.unknown" ];
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

    testIdleOrder = {
      expr = map codes [
        { idle.suspendAfter = 60; }
        { idle.suspendAfter = 300; }
        {
          idle = {
            lockAfter = null;
            suspendAfter = 60;
          };
        }
      ];
      expected = [
        [ "desktop.idle.order" ]
        [ "desktop.idle.order" ]
        [ ]
      ];
    };

    testIdleDefaults = {
      expr = (modelOf { }).idle;
      expected = {
        lockAfter = 300;
        suspendAfter = 900;
      };
    };

    # Binds and widgets that need hardware the host lacks are left out.
    testHardwareRequirements =
      let
        settings = {
          binds."XF86AudioMute" = {
            spawn = [ "wpctl" ];
            requires = [ "audio" ];
          };
          bar = {
            right = [
              "clock"
              "bluetooth"
            ];
            requires.bluetooth = [ "bluetooth" ];
          };
        };

        withFacts =
          facts:
          normalizeWith {
            cfg = evalCfg settings;
            inherit facts;
          };

        bare = withFacts {
          audio = false;
          bluetooth = false;
        };

        full = withFacts {
          audio = true;
          bluetooth = true;
        };
      in
      {
        expr = {
          bareBind = bare.binds ? "XF86AudioMute";
          bareBar = bare.bar.right;
          bareCodes = codesOf desktop.validate bare;
          fullBind = full.binds ? "XF86AudioMute";
          fullBar = full.bar.right;
          unknown = codesOf desktop.validate (withFacts {
            audio = true;
          });
        };
        expected = {
          bareBind = false;
          bareBar = [ "clock" ];
          bareCodes = [ "desktop.bind.requirement.missing" ];
          fullBind = true;
          fullBar = [
            "clock"
            "bluetooth"
          ];
          unknown = [ "desktop.requirement.unknown" ];
        };
      };

    # Mod+D starts the launcher role published by ltp.apps.
    testLauncherBind = {
      expr = hasLine (niriOf { }) ''"Mod+D" { spawn "uwsm" "app" "--" "fuzzel"; }'';
      expected = true;
    };

    testComponents = {
      expr = {
        defaults = codes { };
        unknown = codes { components.bar = "eww"; };
        none = codes { components.bar = null; };
        # Every default names a registered component.
        registered = lib.all (role: desktop.components.${role} ? ${desktop.defaultComponents.${role}}) (
          lib.attrNames desktop.defaultComponents
        );
      };
      expected = {
        defaults = [ ];
        unknown = [ "desktop.component.unknown" ];
        none = [ ];
        registered = true;
      };
    };

    testGreeter = {
      expr = {
        inherit
          (desktop.greeters.tuigreet {
            pkgs.tuigreet = "/tuigreet";
            sessionsDir = "/sessions";
          })
          command
          ;
        unknown = codes { greeter = "gdm"; };
        none = codes { greeter = null; };
      };
      expected = {
        command = "/tuigreet/bin/tuigreet --time --asterisks --remember --remember-session --sessions /sessions";
        unknown = [ "desktop.greeter.unknown" ];
        none = [ ];
      };
    };

    testCompositorsHaveUwsmSessions = {
      expr = lib.mapAttrs (_: entry: builtins.attrNames entry.uwsm) desktop.compositors;
      expected = lib.mapAttrs (_: _: [
        "binPath"
        "comment"
        "extraArgs"
        "prettyName"
      ]) desktop.compositors;
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
            (desktop.systemdUnits {
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
