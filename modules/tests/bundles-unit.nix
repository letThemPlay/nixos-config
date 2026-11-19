{ config, lib, ... }:
let
  bundles = config.ltp.features.bundles;

  inherit (config.flake.nixosModules) bundles-options;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        bundles-options
        { ltp.bundles = settings; }
      ];
    }).config.ltp.bundles;

  modelOf = selected: bundles.normalize { cfg = evalCfg { inherit selected; }; };

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (bundles.validate.all model).diagnostics);

  codes = selected: codesOf (modelOf selected);

  # A small catalogue with a chain, a shared dependency and a broken entry.
  testCatalog = {
    a.description = "a";
    b = {
      description = "b";
      requires = [ "a" ];
    };
    c = {
      description = "c";
      requires = [
        "a"
        "b"
      ];
    };
    broken = {
      description = "broken";
      requires = [ "missing" ];
    };
  };

  withCatalog =
    selected:
    bundles.normalize {
      cfg = evalCfg { inherit selected; };
      catalog = testCatalog;
    };

  contractCases = [
    [ ]
    [ "base" ]
    [
      "unified-ui"
      "laptop"
    ]
    [ "nope" ]
  ];

  tests = {

    testNothingSelected = {
      expr = (modelOf [ ]).active;
      expected = [ ];
    };

    testRequiresPullsIn = {
      expr = lib.sort lib.lessThan (modelOf [ "unified-ui" ]).active;
      expected = [
        "unified-ui"
        "window-management"
      ];
    };

    # A bundle reached twice, directly and through requires, applies once.
    testSharedRequirementOnce = {
      expr =
        lib.sort lib.lessThan
          (withCatalog [
            "c"
            "a"
          ]).active;
      expected = [
        "a"
        "b"
        "c"
      ];
    };

    testSelectionValid = {
      expr = codes [
        "base"
        "unified-ui"
        "window-management"
      ];
      expected = [ ];
    };

    testUnknownBundle = {
      expr = codes [
        "base"
        "flashgdx"
      ];
      expected = [ "bundles.bundle.unknown" ];
    };

    testUnknownRequirement = {
      expr = codesOf (withCatalog [ "a" ]);
      expected = [ "bundles.requires.unknown" ];
    };

    # Every catalogue entry has settings, and nothing else does.
    testEveryBundleConfigured = {
      expr = lib.attrNames bundles.catalog;
      expected = lib.attrNames bundles.configure;
    };

    testCatalogEntriesTyped = {
      expr =
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.catalog = lib.mkOption { type = lib.types.attrsOf bundles.types.entry; }; }
                { inherit (bundles) catalog; }
              ];
            }).config.catalog;
        in
        builtins.deepSeq checked true;
      expected = true;
    };

    # Model contract: normalize output matches types.model.
    testModelContract = {
      expr = map (
        selected:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = bundles.types.model; }; }
                { model = modelOf selected; }
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
      checks.bundles-unit =
        if failures == [ ] then
          pkgs.runCommand "bundles-unit-tests" { } "touch $out"
        else
          throw "bundles unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
