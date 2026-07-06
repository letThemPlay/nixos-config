_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<C-s>";
      action = "<cmd>w<CR>";
      options = {
        silent = true;
        desc = "Save file buffer instantly";
      };
    }
    {
      mode = "i";
      key = "<C-s>";
      action = "<Esc><cmd>w<CR>a";
      options = {
        silent = true;
        desc = "Save file buffer inline from insert mode";
      };
    }
    {
      mode = "v";
      key = "<C-s>";
      action = "<Esc><cmd>w<CR>gv";
      options = {
        silent = true;
        desc = "Save file buffer from visual selection";
      };
    }

    # 🚪 Quit Controls
    {
      mode = "n";
      key = "<leader>qq";
      action = "<cmd>qa<cr>";
      options.desc = "Quit Neovim Entirely";
    }

    # 📂 Interface Layout Toggles
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

    # 🎯 Navigation Navigation splits
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
}
