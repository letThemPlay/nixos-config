_: {
  flake.nixosModules.git =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {

      config = {
        environment.systemPackages = [ pkgs.git ];

        home-manager.users = lib.mapAttrs (_: profile: {
          programs.git = {
            enable = true;
            settings = {
              user = {
                inherit (profile) email;
                name = profile.fullName;
              };
            };
          };
        }) config.ltp.users.registry;
      };
    };
}
