{ config, lib, ... }:
let
  boot = config.ltp.features.boot;

  inherit (config.flake.nixosModules) boot-options;

  #
  # Host settings are evaluated through the real options module so option
  # defaults apply exactly as they do on a host.
  #
  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        boot-options
        { ltp.boot = settings; }
      ];
    }).config.ltp.boot;

  unencrypted = {
    luksName = null;
  };

  encrypted = {
    luksName = "cryptroot";
  };

  modelWith =
    storage: settings:
    boot.normalize {
      cfg = evalCfg settings;
      inherit storage;
    };

  modelOf = modelWith unencrypted;

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (boot.validate.all model).diagnostics);

  codes = settings: codesOf (modelOf settings);

  renderOf =
    settings:
    let
      model = modelOf settings;
    in
    boot.loaders.${model.loader.name}.render { inherit model; };

  secureBoot = {
    secureBoot.enable = true;
  };

  contractCases = [
    { }
    secureBoot
    {
      loader = "systemd-boot";
      generations = 10;
      tpmUnlock.enable = true;
    }
  ];

  tests = {

    testDefaultLoader = {
      expr = (modelOf { }).loader;
      expected = {
        name = "systemd-boot";
        known = true;
        secureBoot = false;
      };
    };

    testSecureBootSelectsLanzaboote = {
      expr = (modelOf secureBoot).loader;
      expected = {
        name = "lanzaboote";
        known = true;
        secureBoot = true;
      };
    };

    testDefaultsAreValid = {
      expr = {
        default = codes { };
        secureBoot = codes secureBoot;
      };
      expected = {
        default = [ ];
        secureBoot = [ ];
      };
    };

    testExplicitLoaderWithoutSigning = {
      expr = codes (secureBoot // { loader = "systemd-boot"; });
      expected = [ "boot.secureBoot.loader.unsupported" ];
    };

    # loader is a string, so a bad name reaches validation.
    testUnknownLoader = {
      expr = codes { loader = "grub"; };
      expected = [ "boot.loader.unknown" ];
    };

    testTpmUnlockNeedsEncryption = {
      expr = {
        unencrypted = codes { tpmUnlock.enable = true; };
        encrypted = codesOf (modelWith encrypted { tpmUnlock.enable = true; });
      };
      expected = {
        unencrypted = [ "boot.tpmUnlock.encryption.missing" ];
        encrypted = [ ];
      };
    };

    testTpmAdapter = {
      expr = {
        encrypted = boot.tpm { model = modelWith encrypted { tpmUnlock.enable = true; }; };
        disabled = boot.tpm { model = modelWith encrypted { }; };
        unencrypted = boot.tpm { model = modelOf { tpmUnlock.enable = true; }; };
      };
      expected = {
        encrypted = {
          active = true;
          devices.cryptroot.crypttabExtraOpts = [ "tpm2-device=auto" ];
          packages = [ "tpm2-tss" ];
        };
        disabled = {
          active = false;
          devices = { };
          packages = [ ];
        };
        unencrypted = {
          active = false;
          devices = { };
          packages = [ ];
        };
      };
    };

    testGenerationsReachEveryLoader = {
      expr = {
        systemd-boot = (renderOf { generations = 7; }).settings.configurationLimit;
        lanzaboote = (renderOf (secureBoot // { generations = 7; })).settings.configurationLimit;
      };
      expected = {
        systemd-boot = 7;
        lanzaboote = 7;
      };
    };

    testLoaderRendering = {
      expr = {
        systemd-boot = renderOf { };
        lanzaboote = renderOf secureBoot;
      };
      expected = {
        systemd-boot = {
          settings.configurationLimit = 5;
          canTouchEfiVariables = true;
          packages = [ ];
          state.directories = [ ];
        };
        lanzaboote = {
          settings = {
            pkiBundle = "/var/lib/sbctl";
            configurationLimit = 5;
          };
          canTouchEfiVariables = false;
          packages = [ "sbctl" ];
          state.directories = [ "/var/lib/sbctl" ];
        };
      };
    };

    # Every model normalize produces satisfies the declared model type.
    testModelContract = {
      expr = map (
        settings:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = boot.types.model; }; }
                { model = modelWith encrypted settings; }
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
      checks.boot-unit =
        if failures == [ ] then
          pkgs.runCommand "boot-unit-tests" { } "touch $out"
        else
          throw "boot unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
