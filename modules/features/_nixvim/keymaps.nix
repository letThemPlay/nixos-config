# modules/features/_nixvim/keymaps.nix
_: {
  programs.nixvim = {
    globals.mapleader = " "; # Set Space bar as leader key

    keymaps = [
      # Core placeholder clear
      {
        mode = "n";
        key = "<Space>";
        action = "<NOP>";
        options.silent = true;
      }

      # =========================================================================
      # 1. EXTENSIONS & SIDEBAR PLUGINS BINDINGS
      # =========================================================================
      {
        mode = [ "n" ];
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Open/Close Neotree";
      }
      {
        mode = "n";
        key = "<leader>gg";
        action = "<cmd>LazyGit<CR>";
        options.desc = "LazyGit (root dir)";
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "<C-/>";
        action = "<cmd>ToggleTerm<cr>";
        options.desc = "Toggle Terminal Window";
      }

      # =========================================================================
      # 2. BUFFERLINE TAB ARCHITECTURE BINDINGS
      # =========================================================================
      {
        mode = "n";
        key = "]b";
        action = "<cmd>BufferLineCycleNext<cr>";
        options.desc = "Cycle to next buffer";
      }
      {
        mode = "n";
        key = "[b";
        action = "<cmd>BufferLineCyclePrev<cr>";
        options.desc = "Cycle to previous buffer";
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<cmd>BufferLineCycleNext<cr>";
        options.desc = "Cycle to next buffer";
      }
      {
        mode = "n";
        key = "<S-h>";
        action = "<cmd>BufferLineCyclePrev<cr>";
        options.desc = "Cycle to previous buffer";
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = "<cmd>bdelete<cr>";
        options.desc = "Delete buffer";
      }
      {
        mode = "n";
        key = "<leader>bl";
        action = "<cmd>BufferLineCloseLeft<cr>";
        options.desc = "Delete buffers to the left";
      }
      {
        mode = "n";
        key = "<leader>bo";
        action = "<cmd>BufferLineCloseOthers<cr>";
        options.desc = "Delete other buffers";
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = "<cmd>BufferLineTogglePin<cr>";
        options.desc = "Toggle pin";
      }
      {
        mode = "n";
        key = "<leader>bP";
        action = "<Cmd>BufferLineGroupClose ungrouped<CR>";
        options.desc = "Delete non-pinned buffers";
      }

      # =========================================================================
      # 3. SMART WRAPPED SCROLLING NAVIGATION (gj/gk on wrapped text blocks)
      # =========================================================================
      {
        mode = [
          "n"
          "x"
        ];
        key = "j";
        action = "v:count == 0 ? 'gj' : 'j'";
        options = {
          expr = true;
          silent = true;
        };
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "<Down>";
        action = "v:count == 0 ? 'gj' : 'j'";
        options = {
          expr = true;
          silent = true;
        };
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "k";
        action = "v:count == 0 ? 'gk' : 'k'";
        options = {
          expr = true;
          silent = true;
        };
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "<Up>";
        action = "v:count == 0 ? 'gk' : 'k'";
        options = {
          expr = true;
          silent = true;
        };
      }

      # =========================================================================
      # 4. WINDOW MANAGEMENT SPLITS DIRECTIONAL ROUTING
      # =========================================================================
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options = {
          desc = "Go to Left Window";
          remap = true;
        };
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options = {
          desc = "Go to Lower Window";
          remap = true;
        };
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options = {
          desc = "Go to Upper Window";
          remap = true;
        };
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options = {
          desc = "Go to Right Window";
          remap = true;
        };
      }

      # =========================================================================
      # 5. WINDOW FRAME DIMENSIONS MODIFICATION LAYOUTS
      # =========================================================================
      {
        mode = "n";
        key = "<C-Up>";
        action = "<cmd>resize +2<cr>";
        options.desc = "Increase Window Height";
      }
      {
        mode = "n";
        key = "<C-Down>";
        action = "<cmd>resize -2<cr>";
        options.desc = "Decrease Window Height";
      }
      {
        mode = "n";
        key = "<C-Left>";
        action = "<cmd>vertical resize -2<cr>";
        options.desc = "Decrease Window Width";
      }
      {
        mode = "n";
        key = "<C-Right>";
        action = "<cmd>vertical resize +2<cr>";
        options.desc = "Increase Window Width";
      }

      # =========================================================================
      # 6. TEXT LINE SELECTION BUBBLING UP/DOWN (Move code selections inline)
      # =========================================================================
      {
        mode = "n";
        key = "<A-j>";
        action = "<cmd>m .+1<cr>==<code>";
        options.desc = "Move Down";
      }
      {
        mode = "n";
        key = "<A-k>";
        action = "<cmd>m .-2<cr>==<code>";
        options.desc = "Move Up";
      }
      {
        mode = "i";
        key = "<A-j>";
        action = "<esc><cmd>m .+1<cr>==gi";
        options.desc = "Move Down";
      }
      {
        mode = "i";
        key = "<A-k>";
        action = "<esc><cmd>m .-2<cr>==gi";
        options.desc = "Move Up";
      }
      {
        mode = "v";
        key = "<A-j>";
        action = ":m '>+1<cr>gv=gv";
        options.desc = "Move Down";
      }
      {
        mode = "v";
        key = "<A-k>";
        action = ":m '<-2<cr>gv=gv";
        options.desc = "Move Up";
      }

      # =========================================================================
      # 7. CHRONOLOGICAL UNDO-SEQUENCE BREAK INJECTIONS
      # =========================================================================
      {
        mode = "i";
        key = ";";
        action = ";<c-g>u";
      }
      {
        mode = "i";
        key = ".";
        action = ".<c-g>u";
      }

      # =========================================================================
      # 8. GLOBAL CONVENIENCE ACTIONS (Save, Clear search highlighting, Quit)
      # =========================================================================
      {
        mode = [
          "i"
          "x"
          "n"
          "s"
        ];
        key = "<C-s>";
        action = "<cmd>w<cr><esc>";
        options.desc = "Save File";
      }
      {
        mode = [
          "i"
          "n"
        ];
        key = "<esc>";
        action = "<cmd>noh<cr><esc>";
        options.desc = "Escape and Clear hlsearch";
      }
      {
        mode = "n";
        key = "<leader>ur";
        action = "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>";
        options.desc = "Redraw / Clear hlsearch / Diff Update";
      }
      {
        mode = "n";
        key = "<leader>qq";
        action = "<cmd>qa<cr>";
        options.desc = "Quit All";
      }

      # =========================================================================
      # 9. SEARCH RE-CENTERING AND SCAN EXPRESSIONS
      # =========================================================================
      {
        mode = "n";
        key = "n";
        action = "'Nn'[v:searchforward].'zv'";
        options = {
          expr = true;
          desc = "Next Search Result";
        };
      }
      {
        mode = "x";
        key = "n";
        action = "'Nn'[v:searchforward]";
        options = {
          expr = true;
          desc = "Next Search Result";
        };
      }
      {
        mode = "o";
        key = "n";
        action = "'Nn'[v:searchforward]";
        options = {
          expr = true;
          desc = "Next Search Result";
        };
      }
      {
        mode = "n";
        key = "N";
        action = "'nN'[v:searchforward].'zv'";
        options = {
          expr = true;
          desc = "Prev Search Result";
        };
      }
      {
        mode = "x";
        key = "N";
        action = "'nN'[v:searchforward]";
        options = {
          expr = true;
          desc = "Prev Search Result";
        };
      }
      {
        mode = "o";
        key = "N";
        action = "'nN'[v:searchforward]";
        options = {
          expr = true;
          desc = "Prev Search Result";
        };
      }

      # =========================================================================
      # 10. DIAGNOSTICS & SYSTEM POS MANAGEMENT INTERFACES
      # =========================================================================
      {
        mode = "n";
        key = "<leader>cd";
        action = "vim.diagnostic.open_float";
        options.desc = "Line Diagnostics";
      }
      {
        mode = "n";
        key = "]d";
        action = "diagnostic_goto(true)";
        options.desc = "Next Diagnostic";
      }
      {
        mode = "n";
        key = "[d";
        action = "diagnostic_goto(false)";
        options.desc = "Prev Diagnostic";
      }
      {
        mode = "n";
        key = "]e";
        action = "diagnostic_goto(true 'ERROR')";
        options.desc = "Next Error";
      }
      {
        mode = "n";
        key = "[e";
        action = "diagnostic_goto(false 'ERROR')";
        options.desc = "Prev Error";
      }
      {
        mode = "n";
        key = "]w";
        action = "diagnostic_goto(true 'WARN')";
        options.desc = "Next Warning";
      }
      {
        mode = "n";
        key = "[w";
        action = "diagnostic_goto(false 'WARN')";
        options.desc = "Prev Warning";
      }
      {
        mode = "n";
        key = "<leader>ui";
        action = "vim.show_pos";
        options.desc = "Inspect Pos";
      }

      # ==============================================================================
      # 11. TOGGLETERM BUILT-IN SUB-SHELL NAVIGATION INTERFACES# =========================================================================
      {
        mode = "t";
        key = "";
        action = "<c-\>";
        options.desc = "Enter Normal Mode";
      }
      {
        mode = "t";
        key = "";
        action = "wincmd h";
        options.desc = "Go to Left Window";
      }
      {
        mode = "t";
        key = "";
        action = "wincmd j";
        options.desc = "Go to Lower Window";
      }
    ];
  };
}
