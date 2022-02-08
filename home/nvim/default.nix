{ config, pkgs, ... }:
let
  vimSettings = builtins.readFile ./settings.vim;
in {
  programs.neovim = {
    package = pkgs.neovim-nightly;
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
        nvim-autopairs
        minimap-vim
        telescope-nvim
        nord-vim

        # LSP
        nvim-lspconfig
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        nvim-cmp
        cmp-vsnip
        vim-vsnip
        lspkind-nvim
        null-ls-nvim
        nvim-lsp-ts-utils
        (nvim-treesitter.withPlugins
          (plugins: pkgs.tree-sitter.allGrammars)
        )
        
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

  home = {
    packages = with pkgs; [
      tree-sitter
      # Language Servers
      beam.packages.erlang.elixir_ls
      java-language-server
      pyright
      rnix-lsp
      nodejs
      nodePackages.typescript-language-server
      nodePackages.eslint_d
      nodePackages.prettier
    ];
  };
}
