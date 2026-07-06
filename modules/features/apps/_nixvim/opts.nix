{ pkgs, ... }: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    extraPackages = [
      pkgs.ripgrep
    ];

    globals.mapleader = " ";

    opts = {
      number = true;
      relativenumber = false;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;
      termguicolors = true;
      wrap = false;
    };
  };
}
