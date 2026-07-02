{ inputs, ... }: {
  flake.nixosModules.nixvim =
    { config, lib, ... }:
    let
      cfg = config.features.nixvim;
    in
    {
      options.features.nixvim.enable = lib.mkEnableOption "NixVim declarative Neovim environment" // {
        default = false;
      };

      config = lib.mkIf cfg.enable {
        home-manager.sharedModules = [
          inputs.nixvim.homeModules.nixvim

          ({ pkgs, ... }: {
            programs.nixvim = {
              enable = true;
              defaultEditor = true;

              nixpkgs.source = inputs.nixpkgs;

              extraPackages = [
                pkgs.ripgrep
              ];

              opts = {
                number = true;
                relativenumber = true;
                shiftwidth = 2;
                tabstop = 2;
                expandtab = true;
                smartindent = true;
                termguicolors = true;
                wrap = false;
              };

              globals.mapleader = " ";

              plugins = {
                treesitter.enable = true;

                telescope = {
                  enable = true;
                  keymaps = {
                    "<leader>ff" = "find_files";
                    "<leader>fg" = "live_grep";
                    "<leader>fb" = "buffers";
                  };
                };

                lualine = {
                  enable = true;
                  settings.options.theme = "auto";
                };

                neo-tree = {
                  enable = true;
                  settings = {
                    close_if_last_window = true;
                  };
                };

                nvim-autopairs.enable = true;
              };

              keymaps = [
                {
                  mode = "n";
                  key = "<leader>e";
                  action = "<cmd>Neotree toggle<cr>";
                  options.desc = "Toggle Neo-tree Panel";
                }
                {
                  mode = "n";
                  key = "<leader>v";
                  action = "<cmd>vsplit<cr>";
                  options.desc = "Vertical Window Split";
                }
                {
                  mode = "n";
                  key = "<leader>h";
                  action = "<cmd>split<cr>";
                  options.desc = "Horizontal Window Split";
                }
              ];
            };

            stylix.targets.nixvim.enable = true;
          })
        ];
      };
    };
}
