{ config, lib, ... }:
let
  nix = config.ltp.features.nix;

  inherit (config.flake.nixosModules) nix-options;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        nix-options
        { ltp.nix = settings; }
      ];
    }).config.ltp.nix;

  modelOf = settings: nix.normalize { cfg = evalCfg settings; };

  codes =
    settings: lib.sort lib.lessThan (map (d: d.code) (nix.validate.all (modelOf settings)).diagnostics);

  settingsOf = settings: nix.settings { model = modelOf settings; };

  contractCases = [
    { }
    {
      defaultCaches = false;
      gc.enable = true;
    }
    {
      caches.extra = {
        url = "https://example.cachix.org";
        key = "example.cachix.org-1:AAAA=";
      };
    }
    { ld.enable = true; }
    {
      ld = {
        enable = true;
        defaultLibraries = false;
        libraries = [ "openal" ];
      };
    }
  ];

  tests = {

    # The defaults are today's effective settings.
    testDefaults = {
      expr = settingsOf { };
      expected = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            "pipe-operators"
          ];
          auto-optimise-store = true;
          substituters = [ "https://nix-community.cachix.org" ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        };
        gc = {
          automatic = false;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
        ld = {
          enable = false;
          libraries = nix.defaultLdLibraries;
        };
      };
    };

    # Added libraries follow the defaults, each once.
    testLdLibraries = {
      expr = {
        added = (settingsOf { ld.libraries = [ "openal" ]; }).ld.libraries;
        only =
          (settingsOf {
            ld = {
              defaultLibraries = false;
              libraries = [
                "SDL2"
                "openal"
                "SDL2"
              ];
            };
          }).ld.libraries;
      };
      expected = {
        added = nix.defaultLdLibraries ++ [ "openal" ];
        only = [
          "SDL2"
          "openal"
        ];
      };
    };

    # Unknown libraries are reported only when nix-ld is on.
    testLdUnknown = {
      expr =
        map
          (
            enable:
            map (d: d.code)
              (nix.validate.all (
                nix.normalize {
                  cfg = evalCfg {
                    package = "nix";
                    ld = {
                      inherit enable;
                      defaultLibraries = false;
                      libraries = [ "no-such-lib" ];
                    };
                  };
                  hasPackage = path: path != "no-such-lib";
                }
              )).diagnostics
          )
          [
            true
            false
          ];
      expected = [
        [ "nix.ld.library.unknown" ]
        [ ]
      ];
    };

    testDefaultsAreValid = {
      expr = codes { };
      expected = [ ];
    };

    testRequiredFeature = {
      expr = codes {
        experimentalFeatures = [
          "nix-command"
          "flakes"
        ];
      };
      expected = [ "nix.experimentalFeatures.missing" ];
    };

    testCacheFormats = {
      expr = codes {
        caches.bad = {
          url = "http://cache.example";
          key = "nope";
        };
      };
      expected = [
        "nix.cache.key.format"
        "nix.cache.url.format"
      ];
    };

    # NixOS adds the official cache itself, with or without the slash.
    testOfficialCacheDuplicate = {
      expr =
        map
          (
            url:
            codes {
              caches.official = {
                inherit url;
                key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
              };
            }
          )
          [
            "https://cache.nixos.org"
            "https://cache.nixos.org/"
          ];
      expected = [
        [ "nix.cache.url.duplicate" ]
        [ "nix.cache.url.duplicate" ]
      ];
    };

    testDefaultCachesOff = {
      expr = (settingsOf { defaultCaches = false; }).settings.substituters;
      expected = [ ];
    };

    testGc = {
      expr = {
        rendered =
          (settingsOf {
            gc = {
              enable = true;
              olderThan = "14d";
            };
          }).gc;
        badFormat = codes {
          gc = {
            enable = true;
            olderThan = "soon";
          };
        };
        ignoredWhenOff = codes { gc.olderThan = "soon"; };
      };
      expected = {
        rendered = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };
        badFormat = [ "nix.gc.olderThan.format" ];
        ignoredWhenOff = [ ];
      };
    };

    testUnknownPackage = {
      expr =
        map (d: d.code)
          (nix.validate.all (
            nix.normalize {
              cfg = evalCfg { };
              hasPackage = _: false;
            }
          )).diagnostics;
      expected = [ "nix.package.unknown" ];
    };

    testModelContract = {
      expr = map (
        settings:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = nix.types.model; }; }
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
      checks.nix-unit =
        if failures == [ ] then
          pkgs.runCommand "nix-unit-tests" { } "touch $out"
        else
          throw "nix unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
