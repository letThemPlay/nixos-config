{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = [
      pkgs.vimPlugins.lazygit-nvim
    ];

    extraConfigLua = ''
      require("telescope").load_extension("lazygit")
    '';

    plugins = {
      bufferline = {
        enable = true;
        settings = {
          options = {
            diagnostics = "nvim_lsp";
            mode = "buffers";
            close_icon = " ";
            buffer_close_icon = "   ";
            modified_icon = "   ";

            offsets = [
              {
                filetype = "neo-tree";
                text = "Neo-tree";
                highlight = "Directory";
                text_align = "left";
              }
            ];
          };
        };
      };

      gitsigns.enable = true;

      hmts.enable = false; # Explicitly handled Home Manager Template Syntax bypass

      lualine = {
        enable = true;
        settings = {
          options.globalstatus = true;

          # +-------------------------------------------------+
          # | A | B | C                             X | Y | Z |
          # +-------------------------------------------------+
          sections = {
            lualine_a = [ "mode" ];
            lualine_b = [ "branch" ];
            lualine_c = [
              "filename"
              "diff"
            ];

            lualine_x = [
              "diagnostics"

              # Injected Lua function to fetch and display the active LSP engine name
              {
                __unkeyed.__raw = ''
                  function()
                      local msg = ""
                      local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
                      local clients = vim.lsp.get_active_clients()
                      if next(clients) == nil then
                          return msg
                      end
                      for _, client in ipairs(clients) do
                          local filetypes = client.config.filetypes
                          if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                              return client.name
                          end
                      end
                      return msg
                  end
                '';
                icon = "";
                color.fg = "#ffffff";
              }

              "encoding"
              "fileformat"
              "filetype"
            ];
          };
        };
      };

      neo-tree = {
        enable = true;
        settings = {
          add_blank_line_at_top = false;
          sources = [
            "filesystem"
            "buffers"
            "git_status"
            "document_symbols"
          ];

          default_component_configs = {
            indent = {
              with_expanders = true;
              expander_collapsed = "";
              expander_expanded = " ";
              expander_highlight = "NeoTreeExpander";
            };

            git_status = {
              symbols = {
                added = " ";
                conflict = "   ";
                deleted = "  ";
                ignored = " ";
                modified = " ";
                renamed = "  ";
                staged = "  ";
                unstaged = "";
                untracked = "";
              };
            };
          };

          filesystem = {
            bind_to_cwd = false;
            follow_current_file = {
              enabled = true;
            };
          };
        };
      };

      nvim-autopairs = {
        enable = true;
        settings = {
          disable_filetype = [
            "TelescopePrompt"
            "vim"
          ];
        };
      };

      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>b" = "buffers";
          "<leader>fh" = "help_tags";
          "<leader>fd" = "diagnostics";
          "<C-p>" = "git_files";
          "<leader>p" = "oldfiles";
          "<C-f>" = "live_grep";
        };

        settings.defaults = {
          file_ignore_patterns = [
            "^.git/"
            "^.mypy_cache/"
            "^__pycache__/"
            "^output/"
            "^data/"
            "%.ipynb"
          ];
          set_env.COLORTERM = "truecolor";
        };
      };

      toggleterm = {
        enable = true;
        settings = {
          size = 20;
          shell = "zsh";
        };
      };

      treesitter = {
        enable = true;
        nixvimInjections = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
        folding = {
          enable = true;
        };
      };

      treesitter-refactor = {
        enable = false;
        settings = {
          highlight_definitions = {
            enable = true;
            clear_on_cursor_move = false;
          };
        };
      };

      web-devicons.enable = true;

      which-key.enable = true;

      zen-mode = {
        enable = true;
        settings.window = {
          width = 0.8;
        };
      };
    };
  };
}
