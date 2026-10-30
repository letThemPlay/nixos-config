{ inputs, ... }: {

  flake.nixosModules.secrets =
    { config, lib, ... }:
    let
      identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    in
    {
      imports = [
        inputs.agenix.nixosModules.default
      ];

      config = {
        age = { inherit identityPaths; };

        #
        # The decryption identities must survive a root rollback. They
        # are symlinked in initrd because agenix decrypts during
        # activation, before stage-2 preservation mounts exist.
        #
        # Uses the local list: reading config.age here would loop
        # through the storage module, which consumes persistence.state.
        #
        ohmydarlings.storage.persistence.state.files = lib.mkIf config.ohmydarlings.storage.enable (
          map (file: {
            inherit file;
            how = "symlink";
            inInitrd = true;
            configureParent = true;
          }) identityPaths
        );
      };
    };

  perSystem = { pkgs, ... }: {
    devShells.secrets = pkgs.mkShellNoCC {
      buildInputs = [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  };
}
