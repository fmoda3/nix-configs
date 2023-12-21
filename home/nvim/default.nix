{ config, pkgs, lib, ... }:
with lib;
let
  python-debug = pkgs.python3.withPackages (p: with p; [ debugpy ]);
in
{
  config = mkIf config.my-home.useNeovim {
    programs.neovim = {
      package = pkgs.neovim-nightly;
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      plugins = with pkgs.vimPlugins; [
        # Basics
        vim-sensible
        # Add syntax/detection/indentation for langs
        vim-elixir
        vim-nix
        kotlin-vim
        dart-vim-plugin
        vim-flutter

        # File Tree
        nvim-web-devicons
        nvim-tree-lua
        # Status line
        feline-nvim
        # Git info
        gitsigns-nvim
        # Indent lines
        indent-blankline-nvim
        # Auto close
        nvim-autopairs
        # Fuzzy finder window
        telescope-nvim
        # Diagnostics window
        trouble-nvim
        # Keybindings window
        legendary-nvim
        # Better native input/select windows
        dressing-nvim
        # Tabs
        bufferline-nvim
        # Smooth scrolling
        vim-smoothie
        # Peek line search
        numb-nvim
        # Fast navigation
        leap-nvim
        # Rainbow brackets
        rainbow-delimiters-nvim
        # Notify window
        nvim-notify
        # Commenting
        comment-nvim

        # Syntax highlighting
        nvim-treesitter.withAllGrammars

        # LSP
        nvim-lspconfig
        nvim-lsp-ts-utils
        # Mostly for linting
        null-ls-nvim
        # LSP status window
        fidget-nvim
        # Code actions sign
        nvim-lightbulb
        # Highlight selected symbol
        vim-illuminate

        # Completions
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-nvim-lsp-signature-help
        nvim-cmp
        lspkind-nvim

        # Snippets
        luasnip
        cmp_luasnip

        # Debug adapter protocol
        nvim-dap
        telescope-dap-nvim
        nvim-dap-ui
        nvim-dap-virtual-text

        # theming
        nord-nvim
      ];

      extraPackages = with pkgs; [
        tree-sitter
        nodejs
        # Language Servers
        # Bash
        nodePackages.bash-language-server
        # Dart
        dart
        # Elixir
        beam.packages.erlang.elixir-ls
        # Erlang
        beam.packages.erlang.erlang-ls
        # Haskell
        stable.haskellPackages.haskell-language-server
        # Lua
        lua-language-server
        # Nix
        nil
        nixpkgs-fmt
        statix
        # Python
        pyright
        python-debug
        black
        # Typescript
        nodePackages.typescript-language-server
        # Web (ESLint, HTML, CSS, JSON)
        nodePackages.vscode-langservers-extracted
        # Telescope tools
        ripgrep
        fd
      ];

      extraConfig = ''
        let g:elixir_ls_home = "${pkgs.beam.packages.erlang.elixir-ls}"
        let g:python_debug_home = "${python-debug}"
        :luafile ~/.config/nvim/lua/init.lua
      '';
    };

    xdg.configFile.nvim = {
      source = ./config;
      recursive = true;
    };
  };
}
