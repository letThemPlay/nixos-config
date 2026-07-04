{ inputs, ... }: {
  flake.nixosModules.discord = { pkgs, ... }: {
    config = {
      modules.features.registry.laptop = inputs.self.nixosModules.discord;

      home-manager.sharedModules = [
        (_: {
          programs.discord = {
            enable = true;
            package = pkgs.discord;
          };
          #stylix.targets.discard.enable = true;
        })
      ];
    };
  };
}
