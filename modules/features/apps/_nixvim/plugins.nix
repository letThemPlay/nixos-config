_: {
  programs.nixvim = {
    plugins = {
      treesitter.enable = true;
      nvim-autopairs.enable = true;
      luasnip.enable = true;

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
          filesystem.follow_current_file.enabled = true;
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
        servers.nixd.enable = true;
        keymaps.lspBuf = {
          "gd" = "definition";
          "gr" = "references";
          "K" = "hover";
          "<leader>rn" = "rename";
          "<leader>ca" = "code_action";
        };
      };

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
  };
}
