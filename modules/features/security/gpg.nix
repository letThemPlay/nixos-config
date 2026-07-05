{ inputs, ... }: {
  flake.nixosModules.gpg =
    { config, lib, ... }:
    let
      gpgLib = import "${inputs.self}/modules/_lib/gpg.nix" { inherit inputs; };
    in
    {
      config = {
        home-manager.users = lib.mapAttrs (
          _: profile:
          let
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
              _module.args = { };
            }
        ) config.ltp.users.registry;
      };
    };
}
