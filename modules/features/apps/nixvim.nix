{ inputs, ... }: {
  flake.nixosModules.nixvim =
    {
      config,
      lib,
      ...
    }:
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
                relativenumber = false;
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
                nvim-autopairs.enable = true;

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
                    filesystem = {
                      follow_current_file = {
                        enabled = true;
                      };
                    };
                  };
                };

                toggleterm = {
                  enable = true;
                  settings = {
                    open_mapping = "[[<C-/>]]";
                    direction = "horizontal";
                    size = 15;
                    insert_mappings = true;
                    terminal_mappings = true;
                    start_in_insert = true;
                  };
                };

                lsp = {
                  enable = true;
                  servers = {
                    nixd.enable = true;

                    # Optional: Add any future languages effortlessly by setting to true
                    # bashls.enable = true;
                    # gopls.enable = true;
                  };

                  keymaps.lspBuf = {
                    "gd" = "definition";
                    "gr" = "references";
                    "K" = "hover";
                    "<leader>rn" = "rename";
                    "<leader>ca" = "code_action";
                  };
                };

                luasnip.enable = true;

                cmp = {
                  enable = true;
                  settings = {
                    snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";

                    mapping = {
                      "<C-Space>" = "cmp.mapping.complete()";
                      "<C-e>" = "cmp.mapping.abort()";
                      "<CR>" = "cmp.mapping.confirm({ select = true })";

                      "<C-n>" = "cmp.mapping.select_next_item()";
                      "<C-p>" = "cmp.mapping.select_prev_item()";
                    };

                    sources = [
                      { name = "nvim_lsp"; }
                      { name = "luasnip"; }
                      { name = "path"; }
                      { name = "buffer"; }
                    ];
                  };
                };
              };

              keymaps = [
                {
                  mode = "n";
                  key = "<leader>qq";
                  action = "<cmd>qa<cr>";
                  options.desc = "Quit Neovim Entirely";
                }
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

                # Ctrl Directional Window Jumps
                {
                  mode = "n";
                  key = "<C-h>";
                  action = "<C-w>h";
                  options.desc = "Go to Left Split Window";
                }
                {
                  mode = "n";
                  key = "<C-j>";
                  action = "<C-w>j";
                  options.desc = "Go to Lower Split Window";
                }
                {
                  mode = "n";
                  key = "<C-k>";
                  action = "<C-w>k";
                  options.desc = "Go to Upper Split Window";
                }
                {
                  mode = "n";
                  key = "<C-l>";
                  action = "<C-w>l";
                  options.desc = "Go to Right Split Window";
                }
              ];
            };

            stylix.targets.nixvim.enable = true;
          })
        ];
      };
    };
}
