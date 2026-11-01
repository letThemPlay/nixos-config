#
# Neovim through nixvim, applied when it plays a role (the editor). The
# editor role itself provides the `v` alias and EDITOR.
#
{ inputs, ... }:
{
  home-manager.sharedModules = [
    inputs.nixvim.homeModules.nixvim

    ./opts.nix
    ./keymaps.nix
    ./plugins.nix

    (_: {
      programs.nixvim.nixpkgs.source = inputs.nixpkgs;
    })
  ];
}
