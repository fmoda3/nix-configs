{ config, pkgs, lib, ... }:
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

        # Cache
        impatient-nvim

        # UI
        nvim-web-devicons
        nvim-tree-lua
        # galaxyline-nvim
        feline-nvim
        gitsigns-nvim
        indent-blankline-nvim
        nvim-autopairs
        minimap-vim
        telescope-nvim
        trouble-nvim
        legendary-nvim
        dressing-nvim
        bufferline-nvim
        vim-smoothie
        numb-nvim
        lightspeed-nvim
        nvim-ts-rainbow

        # LSP
        nvim-lspconfig
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-nvim-lsp-signature-help
        nvim-cmp
        cmp-vsnip
        vim-vsnip
        lspkind-nvim
        nvim-lsp-ts-utils
        fidget-nvim
        nvim-lightbulb
        (nvim-treesitter.withPlugins
          (plugins: pkgs.nvim-ts-grammars.allGrammars)
        )
        
        # theming
        nord-nvim
    ];

    extraPackages = with pkgs; [
      tree-sitter
      nodejs
      # Language Servers
      # Bash
      nodePackages.bash-language-server
      # Elixir
      beam.packages.erlang.elixir_ls
      # Erlang
      beam.packages.erlang.erlang-ls
      # Java
      java-language-server
      # Kotlin
      kotlin-language-server
      # Lua
      sumneko-lua-language-server
      # Nix
      rnix-lsp
      # Python
      pyright
      # Typescript
      nodePackages.typescript-language-server
      # Web (ESLint, HTML, CSS, JSON)
      nodePackages.vscode-langservers-extracted
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
