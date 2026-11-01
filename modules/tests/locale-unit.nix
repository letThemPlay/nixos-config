{ config, lib, ... }:
let
  locale = config.flake.features.locale;

  inherit (config.flake.nixosModules) locale-options;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        locale-options
        { ltp.locale = settings; }
      ];
    }).config.ltp.locale;

  modelOf = settings: locale.normalize (evalCfg settings);

  codes =
    settings:
    lib.sort lib.lessThan (map (d: d.code) (locale.validate.all (modelOf settings)).diagnostics);

  contractCases = [
    { }
    {
      timeZone = "UTC";
      language = "C.UTF-8";
      keyboard.session.variant = "extd";
    }
  ];

  tests = {

    # The defaults are the values every host had before.
    testDefaults = {
      expr = modelOf { };
      expected = {
        timeZone = "Europe/London";
        language = "en_GB.UTF-8";
        keyboard = {
          console = "uk";
          session = {
            layout = "gb";
            variant = "";
          };
        };
      };
    };

    testDefaultsAreValid = {
      expr = codes { };
      expected = [ ];
    };

    testFormsAccepted = {
      expr = map codes [
        { timeZone = "UTC"; }
        { timeZone = "America/Argentina/Buenos_Aires"; }
        { language = "C.UTF-8"; }
        { language = "de_DE"; }
      ];
      expected = [
        [ ]
        [ ]
        [ ]
        [ ]
      ];
    };

    testFormsRejected = {
      expr = map codes [
        { timeZone = "London"; }
        { language = "english"; }
        { keyboard.console = ""; }
        { keyboard.session.layout = ""; }
      ];
      expected = [
        [ "locale.timeZone.format" ]
        [ "locale.language.format" ]
        [ "locale.keyboard.console.empty" ]
        [ "locale.keyboard.session.empty" ]
      ];
    };

    # The console keymap and the session layout stay separate.
    testAdapter = {
      expr = locale.nixos { model = modelOf { keyboard.session.variant = "extd"; }; };
      expected = {
        time.timeZone = "Europe/London";
        i18n.defaultLocale = "en_GB.UTF-8";
        console.keyMap = "uk";
        xkb = {
          layout = "gb";
          variant = "extd";
        };
      };
    };

    testModelContract = {
      expr = map (
        settings:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = locale.types.model; }; }
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
      checks.locale-unit =
        if failures == [ ] then
          pkgs.runCommand "locale-unit-tests" { } "touch $out"
        else
          throw "locale unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
