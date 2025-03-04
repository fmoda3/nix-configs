{ config, pkgs, lib, ... }:
with lib;
let
  python-debug = pkgs.python3.withPackages (p: with p; [ debugpy ]);
in
{
  config = mkIf config.my-home.useNeovim {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      extraLuaConfig = ''
        ${builtins.readFile ./config/lua/settings.lua}
        ${builtins.readFile ./config/lua/util.lua}
        ${builtins.readFile ./config/lua/nord-colors.lua}
      '';

      plugins = with pkgs.vimPlugins; [
        # Basics
        vim-sensible
        # Add syntax/detection/indentation for langs
        vim-elixir
        vim-nix
        kotlin-vim
        dart-vim-plugin
        vim-flutter

        # theming
        nord-nvim

        # Smooth scrolling
        vim-smoothie

        # Syntax highlighting
        nvim-treesitter.withAllGrammars

        # Status line
        {
          plugin = galaxyline-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/galaxyline-config.lua;
        }
        # File Tree
        {
          plugin = nvim-tree-lua;
          type = "lua";
          config = builtins.readFile ./config/lua/nvim-tree-config.lua;
        }
        nvim-web-devicons
        # Indent lines
        {
          plugin = indent-blankline-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/indent-blankline-config.lua;
        }
        # Auto close
        {
          plugin = nvim-autopairs;
          type = "lua";
          config = builtins.readFile ./config/lua/autopairs-config.lua;
        }
        # Completions
        {
          plugin = blink-cmp;
          type = "lua";
          config = builtins.readFile ./config/lua/blink-config.lua;
        }
        # LSP
        {
          plugin = nvim-lspconfig;
          type = "lua";
          config = builtins.readFile ./config/lua/lsp-config.lua;
        }
        nvim-lsp-ts-utils
        # Mostly for linting
        none-ls-nvim
        # Highlight selected symbol
        vim-illuminate
        # LSP status window
        {
          plugin = fidget-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/fidget-config.lua;
        }
        # Code actions sign
        {
          plugin = nvim-lightbulb;
          type = "lua";
          config = builtins.readFile ./config/lua/lightbulb-config.lua;
        }
        # Rainbow brackets
        {
          plugin = rainbow-delimiters-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/rainbow-config.lua;
        }
        # Fuzzy finder window
        {
          plugin = telescope-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/telescope-config.lua;
        }
        # Diagnostics window
        {
          plugin = trouble-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/trouble-config.lua;
        }
        # Keybindings window
        {
          plugin = legendary-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/legendary-config.lua;
        }
        # Better native input/select windows
        {
          plugin = dressing-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/dressing-config.lua;
        }
        # Tabs
        {
          plugin = bufferline-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/bufferline-config.lua;
        }
        # Git info
        {
          plugin = gitsigns-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/gitsigns-config.lua;
        }
        # Peek line search
        {
          plugin = numb-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/numb-config.lua;
        }
        # Fast navigation
        {
          plugin = leap-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/leap-config.lua;
        }
        # Debug adapter protocol
        {
          plugin = nvim-dap;
          type = "lua";
          config = builtins.readFile (pkgs.substituteAll {
            src = ./config/lua/dap-config.lua;
            elixir_ls_home = "${pkgs.beam.packages.erlang.elixir-ls}";
            python_debug_home = "${python-debug}";
          });
        }
        telescope-dap-nvim
        nvim-dap-ui
        nvim-dap-virtual-text
        # Notify window
        {
          plugin = nvim-notify;
          type = "lua";
          config = builtins.readFile ./config/lua/notify-config.lua;
        }
        # Commenting
        {
          plugin = comment-nvim;
          type = "lua";
          config = builtins.readFile ./config/lua/comment-config.lua;
        }
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
        # Gleam
        gleam
        # Haskell
        stable.haskellPackages.haskell-language-server
        # Lua
        lua-language-server
        # Nix
        nixd
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
    };
  };
}
