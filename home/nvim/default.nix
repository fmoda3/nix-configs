{ config, pkgs, ... }:
let
  vimSettings = builtins.readFile ./settings.vim;
in {
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
        # Basics
        vim-sensible
        vim-commentary
        vim-sneak
        vim-nix
        vim-polyglot

        # UI
        nvim-web-devicons
        nvim-tree-lua
        galaxyline-nvim
        indent-blankline-nvim
        vim-signify
        pears-nvim

        # LSP
        nvim-lspconfig
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        # cmp-cmdline
        nvim-cmp
        cmp-vsnip
        vim-vsnip
        lspkind-nvim
        
        # theming
        nord-vim
    ];

    extraConfig = ''
      :luafile ~/.config/nvim/lua/init.lua
    '';
  };

  xdg.configFile.nvim = {
    source = ./config;
    recursive = true;
  };
}
