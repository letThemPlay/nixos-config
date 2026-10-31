{ config, lib, ... }:
let
  identity = config.flake.subsystems.identity;

  inherit (config.flake.nixosModules) identity-api;

  alice = {
    fullName = "Alice";
    email = "alice@example.com";
    enable = true;
  };

  #
  # Settings are evaluated through the real API module, so user files
  # get the same type checks as on a host.
  #
  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        identity-api
        { ltp.identity = settings; }
      ];
    }).config.ltp.identity;

  persistentRoot = {
    ephemeralRoot = false;
    statePath = null;
  };

  ephemeralRoot = {
    ephemeralRoot = true;
    statePath = "/persist";
  };

  context = {
    hasPackage =
      name:
      builtins.elem name [
        "firefox"
        "vlc"
      ];
  };

  modelWith =
    storage: settings:
    identity.normalize {
      cfg = evalCfg settings;
      inherit storage context;
    };

  modelOf = modelWith persistentRoot;

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (identity.validate.all model).diagnostics);

  codes = settings: codesOf (modelOf settings);

  withAlice = extra: {
    users.alice = alice // extra;
    knownFeatures = [ "flashgbx" ];
  };

  contractCases = [
    { }
    (withAlice { admin = true; })
    {
      users = {
        inherit alice;
        bob = alice // {
          enable = false;
        };
      };
    }
  ];

  tests = {

    testDerivedGroups = {
      expr =
        map
          (
            admin:
            (modelOf (withAlice {
              inherit admin;
            })).users.alice.groups
          )
          [
            false
            true
          ];
      expected = [
        [
          "video"
          "audio"
        ]
        [
          "video"
          "audio"
          "wheel"
        ]
      ];
    };

    testExtraGroupsFollowDefaults = {
      expr =
        (modelOf (withAlice {
          extraGroups = [ "dialout" ];
        })).users.alice.groups;
      expected = [
        "video"
        "audio"
        "dialout"
      ];
    };

    testPasswordFileOnEphemeralRoot = {
      expr = {
        ephemeral = (modelWith ephemeralRoot (withAlice { })).users.alice.passwordFile;
        persistent = (modelOf (withAlice { })).users.alice.passwordFile;
        explicit =
          (modelOf (withAlice { } // { passwordDirectory = "/secrets"; })).users.alice.passwordFile;
      };
      expected = {
        ephemeral = "/persist/secrets/passwords/alice";
        persistent = null;
        explicit = "/secrets/alice";
      };
    };

    testDisabledUserExcluded = {
      expr =
        lib.attrNames
          (modelOf {
            users = {
              inherit alice;
              bob = alice // {
                enable = false;
              };
            };
          }).users;
      expected = [ "alice" ];
    };

    testValidUser = {
      expr = codes (withAlice {
        theme = "catppuccin";
        extraPackages = [ "firefox" ];
        features = [ "flashgbx" ];
      });
      expected = [ ];
    };

    testUnknownPackage = {
      expr = codes (withAlice {
        extraPackages = [
          "firefox"
          "nope"
        ];
      });
      expected = [ "identity.user.package.unknown" ];
    };

    testUnknownFeature = {
      expr = codes (withAlice {
        features = [ "flashgdx" ];
      });
      expected = [ "identity.user.feature.unknown" ];
    };

    # Without knownFeatures the feature check is skipped, as in the VM test.
    testMissingFeatureListSkipsCheck = {
      expr = codesOf (
        identity.normalize {
          cfg = evalCfg {
            users.alice = alice // {
              features = [ "nope" ];
            };
          };
          storage = persistentRoot;
          inherit context;
        }
      );
      expected = [ ];
    };

    testNoUsersWarns = {
      expr = codes { };
      expected = [ "identity.users.none" ];
    };

    testUnknownUserFieldFails = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq
            (evalCfg {
              users.alice = alice // {
                defaultShell = "zsh";
              };
            }).users
            true
        )).success;
      expected = false;
    };

    testUsernameIsReadOnly = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq
            (evalCfg {
              users.alice = alice // {
                username = "bob";
              };
            }).users
            true
        )).success;
      expected = false;
    };

    testWithFeature = {
      expr = lib.attrNames (
        identity.query.withFeature
          (modelOf {
            users = {
              alice = alice // {
                features = [ "flashgbx" ];
              };
              carol = alice;
            };
          }).users
          "flashgbx"
      );
      expected = [ "alice" ];
    };

    testAccountsAdapter = {
      expr =
        (identity.accounts {
          model = modelWith ephemeralRoot (withAlice {
            shell = "zsh";
          });
        }).users;
      expected.alice = {
        isNormalUser = true;
        description = "Alice";
        extraGroups = [
          "video"
          "audio"
        ];
        shell = "zsh";
        passwordFile = "/persist/secrets/passwords/alice";
      };
    };

    testEphemeralAdapter = {
      expr = {
        ephemeral =
          let
            adapter = identity.ephemeral { model = modelWith ephemeralRoot (withAlice { }); };
          in
          {
            inherit (adapter) active mutableUsers;
            seed = lib.attrNames adapter.machineIdSeed;
          };
        persistent = (identity.ephemeral { model = modelOf (withAlice { }); }).active;
      };
      expected = {
        ephemeral = {
          active = true;
          mutableUsers = false;
          seed = [ "/sysroot/persist/etc/machine-id" ];
        };
        persistent = false;
      };
    };

    testHomeAdapter = {
      expr =
        (identity.home {
          model = modelOf (withAlice {
            extraPackages = [ "vlc" ];
          });
          stateVersion = "26.05";
        }).users;
      expected.alice.home = {
        username = "alice";
        stateVersion = "26.05";
        packages = [ "vlc" ];
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
                { options.model = lib.mkOption { type = identity.types.model; }; }
                { model = modelWith ephemeralRoot settings; }
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
      checks.identity-unit =
        if failures == [ ] then
          pkgs.runCommand "identity-unit-tests" { } "touch $out"
        else
          throw "identity unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
