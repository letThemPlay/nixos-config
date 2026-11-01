{ config, lib, ... }:
let
  secrets = config.flake.subsystems.secrets;

  inherit (config.flake.nixosModules) secrets-api;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        secrets-api
        { ltp.secrets = settings; }
      ];
    }).config.ltp.secrets;

  # A fake keyring and rules; files are checked in the real repository.
  keys = {
    hosts.box = "ssh-ed25519 BOX";
    users.alice = "ssh-ed25519 ALICE";
  };

  rules = {
    "tailscale-authkey.age".publicKeys = [ keys.users.alice ];
  };

  modelWith =
    {
      hostName ? "box",
      sshd ? true,
      ruleset ? rules,
    }:
    settings:
    secrets.normalize {
      cfg = evalCfg settings;
      inherit hostName sshd keys;
      rules = ruleset;
    };

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (secrets.validate.all model).diagnostics);

  usesTailscale = {
    files.tailscale-authkey = { };
  };

  forBox = {
    "tailscale-authkey.age".publicKeys = [
      keys.hosts.box
      keys.users.alice
    ];
  };

  contractCases = [
    { }
    usesTailscale
    { files.nope = { }; }
  ];

  tests = {

    # A host that declares no secret needs neither a key nor sshd.
    testNoSecretsNoRequirements = {
      expr = codesOf (
        modelWith {
          hostName = "unknown";
          sshd = false;
        } { }
      );
      expected = [ ];
    };

    testValidSecret = {
      expr = codesOf (modelWith { ruleset = forBox; } usesTailscale);
      expected = [ ];
    };

    testRecipientMissing = {
      expr = codesOf (modelWith { } usesTailscale);
      expected = [ "secrets.recipient.missing" ];
    };

    testMissingFileAndRule = {
      expr = codesOf (modelWith { ruleset = forBox; } { files.nope = { }; });
      expected = [
        "secrets.file.missing"
        "secrets.rule.missing"
      ];
    };

    testHostUnknown = {
      expr = codesOf (modelWith { hostName = "other"; } usesTailscale);
      expected = [ "secrets.host.unknown" ];
    };

    testIdentityMissing = {
      expr = {
        noSshd = codesOf (
          modelWith {
            ruleset = forBox;
            sshd = false;
          } usesTailscale
        );
        provisioned = codesOf (
          modelWith {
            ruleset = forBox;
            sshd = false;
          } (usesTailscale // { hostKeyProvisioned = true; })
        );
        otherIdentity = codesOf (
          modelWith {
            ruleset = forBox;
            sshd = false;
          } (usesTailscale // { identityPaths = [ "/var/lib/agenix/key" ]; })
        );
      };
      expected = {
        noSshd = [ "secrets.identity.missing" ];
        provisioned = [ ];
        otherIdentity = [ ];
      };
    };

    # The repository's own rules: theseus is a recipient of the auth key.
    testRepositoryRules = {
      expr = codesOf (
        secrets.normalize {
          cfg = evalCfg (usesTailscale // { hostKeyProvisioned = true; });
          hostName = "theseus";
          sshd = false;
        }
      );
      expected = [ ];
    };

    testAgenixAdapter = {
      expr =
        let
          rendered = secrets.agenix { model = modelWith { ruleset = forBox; } usesTailscale; };
        in
        {
          inherit (rendered) paths;
          file = baseNameOf rendered.secrets.tailscale-authkey.file;
          inherit (rendered.secrets.tailscale-authkey) owner group mode;
        };
      expected = {
        paths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        file = "tailscale-authkey.age";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

    testModelContract = {
      expr = map (
        settings:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = secrets.types.model; }; }
                { model = modelWith { } settings; }
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
      checks.secrets-unit =
        if failures == [ ] then
          pkgs.runCommand "secrets-unit-tests" { } "touch $out"
        else
          throw "secrets unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
