_: {
  flake.nixosModules.git =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.features.git.enable = lib.mkEnableOption "Git configuration";

      config = lib.mkIf config.features.git.enable {
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
