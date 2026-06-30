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
            userName = profile.fullName;
            userEmail = profile.email;
          };
        }) config.ltp.users.registry;
      };
    };
}
