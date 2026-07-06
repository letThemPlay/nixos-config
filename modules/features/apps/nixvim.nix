{ inputs, ... }: {
  flake.nixosModules.nixvim = _: {
    config = {
      home-manager.sharedModules = [
        inputs.nixvim.homeModules.nixvim

        ./_nixvim/opts.nix
        ./_nixvim/keymaps.nix
        ./_nixvim/plugins.nix

        (_: {
          programs.nixvim.nixpkgs.source = inputs.nixpkgs;
          stylix.targets.nixvim.enable = true;
        })
      ];
    };
  };
}
