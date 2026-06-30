{ inputs, ... }: {
  flake.nixosModules.gpg =
    { config, lib, ... }:
    let
      gpgLib = import "${inputs.self}/modules/_lib/gpg.nix" { inherit inputs; };
    in
    {
      options.features.gpg.enable = lib.mkEnableOption "GPG signature space";

      config = lib.mkIf config.features.gpg.enable {
        # Maps Home Manager settings using the global user registry
        home-manager.users = lib.mapAttrs (
          _: profile:
          let
            # Calls your pure library method effortlessly
            userKeys = gpgLib.importAscFiles profile.username;
          in
          if userKeys != [ ] then
            {
              programs.gpg = {
                enable = true;
                publicKeys = userKeys;
              };

              home.file.".ssh/config".text = ''
                Match host * exec "gpg-connect-agent UPDATESTARTUPTTY /bye"
              '';
            }
          else
            {
              # Safe Fallback: Returns empty config if no keys are found
              _module.args = { };
            }
        ) config.ltp.users.registry;
      };
    };
}
