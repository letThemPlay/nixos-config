{ importAscFiles, ... }: {
  flake.nixosModules.gpg =
    { config, lib, ... }:
    {
      config = {
        home-manager.users = lib.mapAttrs (
          _: profile:
          let
            userKeys = importAscFiles profile.username;
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
