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

  uiFile = file: builtins.readFile (desktop.uiSource + "/${file}");

  # The hand-written shell, relative to its root (the generated files are
  # not in the source).
  uiFiles = map (path: lib.removePrefix "${toString desktop.uiSource}/" (toString path)) (
    builtins.filter (
      path: lib.hasSuffix ".qml" (toString path) || lib.hasSuffix ".js" (toString path)
    ) (lib.filesystem.listFilesRecursive desktop.uiSource)
  );

  # The keys of Icons.qml, which surfaces name.
  iconNames = lib.concatMap (group: group) (
    builtins.filter builtins.isList (
      builtins.split "\"([a-zA-Z]+)\": \"[a-z0-9_]+\"" (uiFile "common/Icons.qml")
    )
  );

  contractCases = [
    { }
    {
      components = {
        bar = "quickshell";
        power = "quickshell";
      };
      ui.commands.networkUi = [ "iwgtk" ];
    }
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
        direct = false;
        command = [ "foo" ];
      };
    };

    testWorkspaceAndWindowBindsRenderToNiri = {
      expr = builtins.filter (line: !hasLine (niriOf { }) line) [
        ''"Mod+1" { focus-workspace 1; }''
        ''"Mod+9" { focus-workspace 9; }''
        ''"Mod+Shift+1" { move-column-to-workspace 1; }''
        ''"Mod+Shift+9" { move-column-to-workspace 9; }''
        ''"Mod+Page_Up" { focus-workspace-up; }''
        ''"Mod+Shift+Page_Down" { move-column-to-workspace-down; }''
        ''"Mod+O" { toggle-overview; }''
        ''"Mod+Shift+Space" { toggle-window-floating; }''
        ''"Mod+Tab" { switch-focus-between-floating-and-tiling; }''
        ''"Mod+Shift+Slash" { show-hotkey-overlay; }''
      ];
      expected = [ ];
    };

    testNightLightValidation = {
      expr = {
        fine = codes { };
        from = codes { nightLight.from = "9pm"; };
        until = codes { nightLight.until = "24:00"; };
        defaults = (modelOf { }).nightLight;
      };
      expected = {
        fine = [ ];
        from = [ "desktop.nightLight.time.format" ];
        until = [ "desktop.nightLight.time.format" ];
        defaults = {
          from = "21:00";
          until = "07:00";
          temperature = 4000;
        };
      };
    };

    # The recorder asks every compositor which output has focus.
    testCompositorsNameFocusedOutput = {
      expr = lib.mapAttrs (_: entry: builtins.attrNames entry.focusedOutput) desktop.compositors;
      expected = lib.mapAttrs (_: _: [
        "command"
        "filter"
      ]) desktop.compositors;
    };

    testScreenshotBindsRenderToNiri = {
      expr = builtins.filter (line: !hasLine (niriOf { }) line) [
        ''"Print" { screenshot-screen; }''
        ''"Mod+Print" { screenshot-window; }''
      ];
      expected = [ ];
    };

    testMonitorBindsRenderToNiri = {
      expr = builtins.filter (line: !hasLine (niriOf { }) line) [
        ''"Mod+Ctrl+Left" { focus-monitor-left; }''
        ''"Mod+Ctrl+Right" { focus-monitor-right; }''
        ''"Mod+Shift+Ctrl+Left" { move-column-to-monitor-left; }''
        ''"Mod+Shift+Ctrl+Right" { move-column-to-monitor-right; }''
      ];
      expected = [ ];
    };

    testDisplaysRenderToKanshi = {
      expr = desktop.kanshi {
        inherit
          (modelOf {
            displays.profiles.desk.outputs = {
              "eDP-1".enable = false;
              "Dell U2720Q" = {
                scale = 1.5;
                mode = "3840x2160@60Hz";
                position = {
                  x = 1920;
                  y = 0;
                };
              };
            };
          })
          displays
          ;
      };
      expected = [
        {
          profile = {
            name = "desk";
            outputs = [
              {
                criteria = "Dell U2720Q";
                status = "enable";
                scale = 1.5;
                mode = "3840x2160@60Hz";
                position = "1920,0";
              }
              {
                criteria = "eDP-1";
                status = "disable";
              }
            ];
          };
        }
      ];
    };

    testDisplayValidation = {
      expr = {
        none = codes { displays.profiles.empty.outputs = { }; };
        scale = codes {
          displays.profiles.desk.outputs."eDP-1".scale = 0;
        };
        fine = codes {
          displays.profiles.desk.outputs."eDP-1".scale = 1.25;
        };
        nothing = (modelOf { }).displays.profiles;
      };
      expected = {
        none = [ "desktop.display.profile.outputs.none" ];
        scale = [ "desktop.display.outputs.scale" ];
        fine = [ ];
        nothing = { };
      };
    };

    # The vocabulary and niri's map must not drift apart.
    testNiriMapsEveryAction = {
      expr = builtins.filter (action: !(desktop.compositors.niri.actions ? ${action})) desktop.actions;
      expected = [ ];
    };

    testHotkeyOverlaySkippedAtLogin = {
      expr = hasLine (niriOf { }) "hotkey-overlay {\n    skip-at-startup\n}";
      expected = true;
    };

    # A poke into a running component skips the session wrapper; only that.
    testDirectBindSkipsSessionWrapper = {
      expr =
        let
          text = niriOf {
            binds = {
              "Mod+A" = {
                spawn = [ "poke" ];
                direct = true;
              };
              "Mod+B".spawn = [ "app" ];
            };
          };
        in
        map (hasLine text) [
          ''"Mod+A" { spawn "poke"; }''
          ''"Mod+B" { spawn "uwsm" "app" "--" "app"; }''
        ];
      expected = [
        true
        true
      ];
    };

    # The roles selecting the shell are what it draws; the rest stay out.
    testUiSurfaces = {
      expr = {
        defaults = (modelOf { }).ui.surfaces;
        selected =
          (modelOf {
            components = {
              bar = "quickshell";
              batteryAlerts = "quickshell";
              dock = "quickshell";
              locker = "quickshell";
              osd = "quickshell";
              polkit = "quickshell";
              quicksettings = "quickshell";
              power = "quickshell";
            };
          }).ui.surfaces;
      };
      expected = {
        defaults = [ ];
        selected = [
          "bar"
          "batteryAlerts"
          "dock"
          "locker"
          "osd"
          "polkit"
          "power"
          "quicksettings"
        ];
      };
    };

    # Waybar's own modules mean nothing to the shell's bar, and only there.
    testUiWidgets =
      let
        bar = {
          left = [ "workspaces" ];
          right = [ "custom/weather" ];
        };
      in
      {
        expr = {
          unknown = codes {
            components.bar = "quickshell";
            inherit bar;
          };
          waybar = codes { inherit bar; };
          known = codes {
            components.bar = "quickshell";
            bar.left = desktop.uiWidgets;
          };
        };
        expected = {
          unknown = [ "desktop.ui.widget.unknown" ];
          waybar = [ ];
          known = [ ];
        };
      };

    # Validation's list and the bar's own map must name the same widgets.
    testUiWidgetsAreDrawn = {
      expr = builtins.filter (
        widget: !lib.hasInfix ''"${widget}": '' (uiFile "bar/Bar.qml")
      ) desktop.uiWidgets;
      expected = [ ];
    };

    # Every colour role resolves through the user's scheme.
    testThemeUsesScheme =
      let
        tokens =
          (lib.evalModules {
            modules = [
              config.flake.nixosModules.theme-options
              { ltp.theme = { }; }
            ];
          }).config.ltp.theme.appearance;

        text = desktop.quickshell.theme {
          tokens = config.ltp.features.theme.uiTokens { appearance = tokens; };
          colors = lib.genAttrs (lib.unique (builtins.attrValues config.ltp.features.theme.uiPalette)) (
            slot: "aaaa${lib.substring 4 2 slot}"
          );
        };
      in
      {
        expr = map (hasLine text) [
          ''readonly property color accent: "#aaaa0D"''
          ''readonly property color background: "#aaaa00"''
          ''readonly property color danger: "#aaaa08"''
          "readonly property int spaceMd: 12"
          "readonly property int radiusLg: 10"
          "readonly property int radiusMd: 8"
          ''readonly property string iconFont: "Material Symbols Rounded"''
        ];
        expected = [
          true
          true
          true
          true
          true
          true
          true
        ];
      };

    # The look lives in one place: a colour or font written into a surface
    # would stop following the theme.
    testSurfacesTakeLookFromTheme = {
      expr = builtins.filter (
        file:
        let
          text = uiFile file;
        in
        builtins.match ".*\"#[0-9a-fA-F]+\".*" text != null
        || builtins.match ".*font\\.family: \".*" text != null
      ) uiFiles;
      expected = [ ];
    };

    # What the surfaces name directly must be in the icon vocabulary.
    testSurfacesNameKnownIcons =
      let
        known = iconNames;

        named =
          file:
          lib.concatMap (group: group) (
            builtins.filter builtins.isList (builtins.split "(icon|name): \"([a-zA-Z]+)\"" (uiFile file))
          );

        used = lib.unique (
          lib.concatMap (file: lib.filter (word: word != "icon" && word != "name") (named file)) uiFiles
          ++ lib.mapAttrsToList (_: action: action.icon) desktop.powerActions
        );
      in
      {
        expr = builtins.filter (icon: !builtins.elem icon known) used;
        expected = [ ];
      };

    # A bind that pokes the shell must name a target it actually handles.
    testShellBindTargetsExist = {
      expr = map (target: lib.any (file: lib.hasInfix ''target: "${target}"'' (uiFile file)) uiFiles) [
        "dock"
        "launcher"
        "notifications"
        "osd"
        "power"
        "quicksettings"
        "recorder"
      ];
      expected = [
        true
        true
        true
        true
        true
        true
        true
      ];
    };

    # The dock pins the roles in use unless told otherwise, as Quickshell's IDs.
    testDockApps = {
      expr = {
        none = (modelOf { }).dockApps;
        roles =
          (normalizeWith {
            cfg = evalCfg { };
            apps = {
              terminal.desktopEntry = "Alacritty.desktop";
              browser.desktopEntry = "firefox.desktop";
              fileManager.desktopEntry = null;
            };
          }).dockApps;
        chosen =
          (modelOf {
            dockApps = [
              "org.pwmt.zathura.desktop"
              "mpv"
            ];
          }).dockApps;
        empty = (modelOf { dockApps = [ ]; }).dockApps;
      };
      expected = {
        none = [ ];
        roles = [
          "Alacritty"
          "firefox"
        ];
        chosen = [
          "org.pwmt.zathura"
          "mpv"
        ];
        empty = [ ];
      };
    };

    testNotificationHistory = {
      expr = {
        defaults = (modelOf { }).notificationHistory;
        off = (modelOf { notificationHistory.limit = 0; }).notificationHistory.limit;
      };
      expected = {
        defaults = {
          limit = 50;
          days = 7;
        };
        off = 0;
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

    # The bar and the alerts must warn where the hardware feature says.
    testShellSettingsCarryPowerFacts =
      let
        settingsFor =
          facts:
          desktop.quickshell.settings {
            model = normalizeWith {
              cfg = evalCfg { };
              inherit facts;
            };
            inherit (desktop) spawnPrefix;
            pam = {
              config = "x";
              directory = "/x";
            };
            wallpaper = "";
            terminal = [ ];
          };

        text = settingsFor {
          powerProfiles = true;
          batteryLevels = {
            low = 25;
            critical = 8;
          };
        };
      in
      {
        expr = map (hasLine text) [
          "readonly property bool powerProfiles: true"
          ''readonly property var batteryLevels: {"critical":8,"low":25}''
          ''readonly property var notificationHistory: {"days":7,"limit":50}''
          "readonly property var dockApps: []"
        ];
        expected = [
          true
          true
          true
          true
        ];
      };

    # A brightness key does nothing without a backlight, so the bind goes.
    testBrightnessNeedsBacklight =
      let
        withFacts =
          backlight:
          normalizeWith {
            cfg = evalCfg {
              binds."XF86MonBrightnessUp" = {
                spawn = [ "brightness" ];
                direct = true;
                requires = [ "backlight" ];
              };
            };
            facts = {
              inherit backlight;
            };
          };
      in
      {
        expr = {
          without = (withFacts false).binds ? "XF86MonBrightnessUp";
          withBacklight = (withFacts true).binds ? "XF86MonBrightnessUp";
          codes = codesOf desktop.validate (withFacts false);
        };
        expected = {
          without = false;
          withBacklight = true;
          codes = [ "desktop.bind.requirement.missing" ];
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
        # Every default names a registered component, or none.
        registered = lib.all (
          role:
          desktop.defaultComponents.${role} == null
          || desktop.components.${role} ? ${desktop.defaultComponents.${role}}
        ) (lib.attrNames desktop.defaultComponents);
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

    # Without it niri sets no DISPLAY and X11 applications cannot start.
    testNiriProvidesXwayland = {
      expr = builtins.elem "xwayland-satellite" desktop.compositors.niri.system.packages;
      expected = true;
    };

    testWaybarResolvesWidgets = {
      expr = desktop.waybarConfig {
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

      #
      # The icon font is addressed by ligature, so a name it does not have
      # would render as its letters instead of failing. It shapes each one,
      # and proves first that a made-up name would be caught.
      #
      checks.desktop-icons =
        pkgs.runCommand "desktop-icons"
          {
            nativeBuildInputs = [ (pkgs.python3.withPackages (python: [ python.uharfbuzz ])) ];
            icons = desktop.uiSource + "/common/Icons.qml";
            font = "${pkgs.material-symbols}/share/fonts/truetype/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf";
          }
          ''
            python3 ${./_desktop-icons-check.py} "$icons" "$font"
            touch $out
          '';
    };
}
