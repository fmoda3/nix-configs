{ config, pkgs, lib, ... }:
with lib;
let
  # Remove pkgs.python3Packages when build is fixed in nixpkgs
  python-debug = pkgs.python3.withPackages (p: with p; [pkgs.python3Packages.debugpy]);
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
        lightspeed-nvim
        # Rainbow brackets
        nvim-ts-rainbow
        # Notify window
        nvim-notify
        # Commenting
        comment-nvim

        # Syntax highlighting
        (nvim-treesitter.withPlugins
          (plugins: pkgs.nvim-ts-grammars.allGrammars)
        )

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
        # Elixir
        beam.packages.erlang.elixir_ls
        # Erlang
        beam.packages.erlang.erlang-ls
        # Haskell
        stable.haskellPackages.haskell-language-server
        # Java
        java-language-server
        # Kotlin
        kotlin-language-server
        # Lua
        sumneko-lua-language-server
        # Nix
        rnix-lsp
        nixpkgs-fmt
        statix
        # Python
        pyright
        # python-debug
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
        let g:python_debug_home = "${python-debug}"
        let g:elixir_ls_home = "${pkgs.beam.packages.erlang.elixir_ls}"
        :luafile ~/.config/nvim/lua/init.lua
      '';
    };

    xdg.configFile.nvim = {
      source = ./config;
      recursive = true;
    };
  };
}
