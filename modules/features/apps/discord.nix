_: {
  flake.nixosModules.discord = { pkgs, ... }: {
    config = {

      home-manager.sharedModules = [
        (_: {
          programs.discord = {
            enable = true;
            package = pkgs.discord;
          };
          stylix.targets.nixcord.enable = true;
        })
      ];
    };
  };
}
