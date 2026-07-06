{ importAscFiles, ... }: {
  flake.nixosModules.gpg = { config, lib, ... }: {
    config = {
      home-manager.users = lib.mapAttrs (
        _: profile:
        let
          userKeys = profile.username |> importAscFiles;
        in
        lib.optionalAttrs (userKeys != [ ]) {
          programs.gpg = {
            enable = true;
            publicKeys = userKeys;
          };

          home.file.".ssh/config".text = ''
            Match host * exec "gpg-connect-agent UPDATESTARTUPTTY /bye"
          '';
        }
      ) config.ltp.users.registry;
    };
  };
}
