{ inputs, ... }: {
  flake.nixosModules.nixvim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ltp.programs.nixvim;
    in
    {
      options.ltp.programs.nixvim = {
        enable = lib.mkEnableOption "Nixvim modular configuration workspace" // {
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.ripgrep
          pkgs.lazygit
        ];

        home-manager.sharedModules = [
          inputs.nixvim.homeModules.nixvim
          (_: {
            programs.nixvim.nixpkgs.source = inputs.nixpkgs;
          })

          ./_nixvim/default.nix
          ./_nixvim/options.nix
          ./_nixvim/keymaps.nix
          ./_nixvim/_plugins/core.nix
          ./_nixvim/_plugins/lsp.nix
        ];
      };
    };
}
