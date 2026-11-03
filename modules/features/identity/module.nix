{ config, ... }:
let
  identity = config.ltp.features.identity;
in
{
  flake.nixosModules.identity =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib)
        mapAttrs
        mkDefault
        mkIf
        mkMerge
        ;

      cfg = config.ltp.identity;

      # What the users may refer to, as plain data.
      context = {
        hasPackage = name: pkgs ? ${name};
      };

      #
      # The storage facts read only storage's own options, never
      # persistence, so they are safe here even though this module
      # declares persistence.state.
      #
      model = identity.normalize {
        inherit cfg context;
        storage = config.ltp.storage.facts;
      };

      validation = identity.validate.all model;

      accounts = identity.accounts { inherit model; };

      ephemeral = identity.ephemeral { inherit model; };

      gpg = identity.gpg {
        inherit model;
        graphical = false;
      };

      format = diagnostic: "ltp.identity [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      config = mkMerge [

        # Published on every host, like the storage facts.
        {
          ltp.identity.facts = {
            inherit (model) users gpg userDirs;
          };
        }

        (mkIf cfg.enable (mkMerge [

          {
            assertions = errors;

            warnings = map format validation.warnings;
          }

          #
          # Outside the validation.ok guard: validation reads pkgs, which
          # loops back through the storage module when it is a condition
          # on persistence.state. ephemeral.active reads only the storage
          # facts.
          #
          (mkIf ephemeral.active {
            ltp.storage.persistence.state = ephemeral.state;

            services.userborn = ephemeral.userborn;

            boot.initrd.systemd.tmpfiles.settings.preservation = ephemeral.machineIdSeed;

            systemd.services.systemd-machine-id-commit = ephemeral.machineIdCommit;

            users.mutableUsers = ephemeral.mutableUsers;
          })

          #
          # How admins get root. Every registered tool is set explicitly,
          # so the chosen one replaces NixOS's default sudo.
          #
          (mkIf validation.ok {
            security = mapAttrs (name: _: {
              enable = model.escalation.name == name;
            }) identity.escalations;
          })

          # The smartcard holding users' keys needs its device rules.
          (mkIf (model.gpg && gpg.smartcard) {
            hardware.gpgSmartcards.enable = true;
          })

          #
          # Not behind validation.ok: home-manager looks up an account for
          # every published user, so withholding accounts would turn a
          # validation error into a missing-attribute crash. Accounts use
          # none of the validated fields (packages, bundles).
          #
          {
            users.users = mapAttrs (_: account: {
              inherit (account) isNormalUser description extraGroups;

              hashedPasswordFile = mkIf (account.passwordFile != null) (mkDefault account.passwordFile);
            }) accounts.users;
          }

        ]))

      ];
    };
}
