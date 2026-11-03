{ config, inputs, ... }:
let
  secrets = config.ltp.features.secrets;
in
{
  flake.nixosModules.secrets =
    { config, lib, ... }:

    let
      inherit (lib) mapAttrs mkIf mkMerge;

      cfg = config.ltp.secrets;

      model = secrets.normalize {
        inherit cfg;
        inherit (config.networking) hostName;
        sshd = config.services.openssh.enable;
      };

      validation = secrets.validate.all model;

      rendered = secrets.agenix { inherit model; };

      format = diagnostic: "ltp.secrets [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      imports = [
        inputs.agenix.nixosModules.default
      ];

      config = mkMerge [

        # Published on every host, like the other features' facts.
        { ltp.secrets.facts.paths = mapAttrs (name: _: "${config.age.secretsDir}/${name}") cfg.files; }

        (mkIf cfg.enable (mkMerge [

          {
            assertions = errors;

            warnings = map format validation.warnings;

            #
            # The decryption identities must survive a root rollback. They
            # are symlinked in initrd because agenix decrypts during
            # activation, before stage-2 preservation mounts exist.
            #
            # Reads only the identityPaths option: reading config.age here
            # would loop through the storage module, which consumes
            # persistence.state.
            #
            ltp.storage.persistence.state.files = mkIf config.ltp.storage.enable (
              map (file: {
                inherit file;
                how = "symlink";
                inInitrd = true;
                configureParent = true;
              }) cfg.identityPaths
            );
          }

          #
          # Rendering only runs on a valid model; invalid models stop at
          # the assertions above with a readable diagnostic.
          #
          (mkIf validation.ok {
            age = {
              identityPaths = rendered.paths;
              inherit (rendered) secrets;
            };
          })

        ]))

      ];
    };

  perSystem =
    { pkgs, ... }:
    {
      # The agenix CLI: nix develop .#secrets
      devShells.secrets = pkgs.mkShellNoCC {
        buildInputs = [
          inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };
    };
}
