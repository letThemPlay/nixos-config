_: {
  programs.nixvim.clipboard = {
    register = "unnamedplus";
    providers.wl-copy.enable = true;
  };

  programs.nixvim.opts = {
    number = true;
    relativenumber = false; # 👑 Enforces absolute numbering layout
    cursorline = true; # Highlight active visual line positions
    scrolloff = 8; # Enforces a top/bottom scroll cushion layer

    tabstop = 2;
    softtabstop = 2;
    shiftwidth = 2;
    expandtab = true;
    smartindent = true;
    breakindent = true;

    # System workspace cosmetics & performance tweaks
    showtabline = 2; # Always lock tab tracking line visible
    showmode = false; # Disables redundant command mode line text
    termguicolors = true; # Force 24-bit RGB processing profiles
    timeoutlen = 300; # Hotkey chain validation processing timer
    updatetime = 250;
    mouse = "a"; # Globally hook mouse context inputs

    # Buffer processing behaviors
    clipboard = "unnamedplus"; # Bridge directly to host ring buffers
    linebreak = true; # Wrap columns at word character boundaries
    spell = false; # Disable system spellcheck alerts
    swapfile = false; # Suppress continuous disk operations swap chains

    # Window splitting dynamics
    splitbelow = true; # Force horizontal splits downward
    splitright = true; # Force vertical splits outward right
    splitkeep = "screen"; # Preserves continuous buffer viewing scroll points
    cmdheight = 0; # Suppresses bottom CLI line footprint unless focused

    # Folding engine rules
    foldmethod = "manual"; # Reverts structural code folds to user manipulation
    foldenable = false; # Disables collapsed blocks on initial open transitions

    # Menu completion behaviour patterns
    completeopt = [
      "menu"
      "menuone"
      "noselect"
    ];
  };
}
