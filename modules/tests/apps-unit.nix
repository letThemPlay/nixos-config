{ config, lib, ... }:
let
  apps = config.flake.features.apps;

  inherit (config.flake.nixosModules) apps-options;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        apps-options
        { ltp.apps = settings; }
      ];
    }).config.ltp.apps;

  modelOf = settings: apps.normalize { cfg = evalCfg settings; };

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (apps.validate.all model).diagnostics);

  codes = settings: codesOf (modelOf settings);

  contractCases = [
    { }
    {
      roles.browser = null;
      overrides.terminal.execFlag = null;
    }
    { roles.editor = "emacs"; }
    {
      install = [
        "firefox"
        "nope"
      ];
    }
  ];

  tests = {

    # The roles the desktop used to resolve, plus the editor.
    testDefaultRoles = {
      expr = lib.mapAttrs (_: role: {
        inherit (role) app command;
      }) (modelOf { }).roles;
      expected = {
        terminal = {
          app = "alacritty";
          command = [ "alacritty" ];
        };
        editor = {
          app = "nixvim";
          command = [ "nvim" ];
        };
        browser = {
          app = "firefox";
          command = [ "firefox" ];
        };
        fileManager = {
          app = "yazi";
          command = [
            "alacritty"
            "-e"
            "yazi"
          ];
        };
        launcher = {
          app = "fuzzel";
          command = [ "fuzzel" ];
        };
      };
    };

    testDefaultsAreValid = {
      expr = codes { dmenuConsumers = [ "clipboard" ]; };
      expected = [ ];
    };

    testOverrideKeepsOtherFields = {
      expr =
        let
          browser =
            (modelOf {
              overrides.browser.command = [
                "firefox"
                "--new-window"
              ];
            }).roles.browser;
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

    testRoleOff = {
      expr = (modelOf { roles.browser = null; }).roles ? browser;
      expected = false;
    };

    testUnknownApp = {
      expr = codes { roles.editor = "emacs"; };
      expected = [ "apps.app.unknown" ];
    };

    testRoleUnsupported = {
      expr = codes { roles.terminal = "firefox"; };
      expected = [
        "apps.role.unsupported"
        "apps.terminal.missing"
      ];
    };

    # nixvim's program comes from its configure module, not pkgs.
    testPackages = {
      expr = {
        nixvim = codesOf (
          apps.normalize {
            cfg = evalCfg { };
            hasPackage = _: false;
          }
        );
        missing = codesOf (
          apps.normalize {
            cfg = evalCfg { };
            hasPackage = path: path != "yazi";
          }
        );
      };
      expected = {
        nixvim = [
          "apps.package.unknown"
          "apps.package.unknown"
          "apps.package.unknown"
          "apps.package.unknown"
        ];
        missing = [ "apps.package.unknown" ];
      };
    };

    # Any catalogue app can be installed without a role.
    testInstall = {
      expr =
        let
          model = modelOf {
            install = [ "firefox" ];
            roles.browser = null;
          };
        in
        {
          inherit (model.installed.firefox) app package known;
          roles = model.roles ? browser;
        };
      expected = {
        app = "firefox";
        package = "firefox";
        known = true;
        roles = false;
      };
    };

    # An installed app's aliases reach the shell; role-less apps fit no role.
    testInstalledAliases = {
      expr =
        let
          model = modelOf {
            install = [
              "git"
              "eza"
            ];
          };
        in
        {
          gs = model.aliases.gs or null;
          lt = model.aliases.lt or null;
          valid = codesOf model;
        };
      expected = {
        gs = "git status -sb";
        lt = "eza --tree --level=2";
        valid = [ ];
      };
    };

    testRoleOnlyCatalogueApp = {
      expr = codes { roles.terminal = "git"; };
      expected = [
        "apps.role.unsupported"
        "apps.terminal.missing"
      ];
    };

    testInstallUnknown = {
      expr = codes { install = [ "nope" ]; };
      expected = [ "apps.app.unknown" ];
    };

    testInstallPackageMissing = {
      expr = codesOf (
        apps.normalize {
          cfg = evalCfg {
            install = [ "firefox" ];
            roles.browser = null;
          };
          hasPackage = path: path != "firefox";
        }
      );
      expected = [ "apps.package.unknown" ];
    };

    testTerminalWithoutExecFlag = {
      expr = codes { overrides.terminal.execFlag = null; };
      expected = [ "apps.terminal.missing" ];
    };

    testDmenu = {
      expr = {
        ok = codes { dmenuConsumers = [ "clipboard" ]; };
        missing = codes {
          dmenuConsumers = [ "clipboard" ];
          overrides.launcher.dmenu = null;
        };
        unused = codes { overrides.launcher.dmenu = null; };
      };
      expected = {
        ok = [ ];
        missing = [ "apps.dmenu.missing" ];
        unused = [ ];
      };
    };

    testModelContract = {
      expr = map (
        settings:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = apps.types.model; }; }
                { model = modelOf settings; }
              ];
            }).config.model;
        in
        builtins.deepSeq checked true
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
      checks.apps-unit =
        if failures == [ ] then
          pkgs.runCommand "apps-unit-tests" { } "touch $out"
        else
          throw "apps unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
