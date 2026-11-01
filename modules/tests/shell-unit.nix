{ config, lib, ... }:
let
  shell = config.flake.features.shell;

  inherit (config.flake.nixosModules) shell-api;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        shell-api
        { ltp.shell = settings; }
      ];
    }).config.ltp.shell;

  modelOf =
    settings: shells:
    shell.normalize {
      cfg = evalCfg settings;
      users = lib.mapAttrs (_: name: { shell = name; }) shells;
    };

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (shell.validate.all model).diagnostics);

  # render only needs the prompt package's path.
  pkgs = {
    spaceship-prompt = "/spaceship";
  };

  contractCases = [
    {
      settings = { };
      shells = { };
    }
    {
      settings.aliases.g = "git";
      shells = {
        alice = "zsh";
        bob = "bash";
      };
    }
    {
      settings.defaultAliases = false;
      shells.carol = "fish";
    }
  ];

  tests = {

    testAliasesMerge = {
      expr =
        (modelOf {
          aliases = {
            g = "git";
            ll = "eza -l";
          };
        } { }).aliases;
      expected = {
        g = "git";
        ll = "eza -l";
        la = "ls -la";
      };
    };

    testDefaultAliasesOff = {
      expr = (modelOf { defaultAliases = false; } { }).aliases;
      expected = { };
    };

    testShellsInUse = {
      expr =
        (modelOf { } {
          alice = "zsh";
          bob = "bash";
          carol = "zsh";
          dave = "fish";
        }).shells;
      expected = [
        "bash"
        "zsh"
      ];
    };

    testUnknownShell = {
      expr = codesOf (modelOf { } { alice = "fish"; });
      expected = [ "shell.user.unknown" ];
    };

    testKnownShellsAreValid = {
      expr = codesOf (
        modelOf { } {
          alice = "zsh";
          bob = "bash";
        }
      );
      expected = [ ];
    };

    testZshRender = {
      expr =
        let
          zsh =
            (shell.shells.zsh.render {
              aliases.g = "git";
              inherit pkgs;
            }).programs.zsh;
        in
        {
          inherit (zsh) enable enableCompletion shellAliases;
          auto = zsh.autosuggestion.enable;
          syntax = zsh.syntaxHighlighting.enable;
          inherit (zsh) history;
          prompt = lib.hasInfix "/spaceship/share/zsh/themes/spaceship.zsh-theme" zsh.initContent;
        };
      expected = {
        enable = true;
        enableCompletion = true;
        shellAliases.g = "git";
        auto = true;
        syntax = true;
        history = {
          size = 10000;
          path = "$HOME/.zsh_history";
        };
        prompt = true;
      };
    };

    testBashRender = {
      expr =
        (shell.shells.bash.render {
          aliases.g = "git";
          inherit pkgs;
        }).programs.bash.shellAliases;
      expected.g = "git";
    };

    testSystemNeeds = {
      expr = lib.mapAttrs (_: entry: entry.system.programs) shell.shells;
      expected = {
        bash = [ ];
        zsh = [ "zsh" ];
      };
    };

    testModelContract = {
      expr = map (
        case:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = shell.types.model; }; }
                { model = modelOf case.settings case.shells; }
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
      checks.shell-unit =
        if failures == [ ] then
          pkgs.runCommand "shell-unit-tests" { } "touch $out"
        else
          throw "shell unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
