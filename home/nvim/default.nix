{ config, pkgs, lib, ... }:
let
  cfg = config.my-home;
  python-debug = pkgs.python3.withPackages (p: with p; [ debugpy ]);
  nvimLib = import ./lib.nix { inherit pkgs; };
  inherit (nvimLib) mkLuaPlugin mkLuaPluginWithVars;
in
{
  config = lib.mkIf cfg.useNeovim {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      initLua = ''
        ${builtins.readFile ./config/lua/settings.lua}
        ${builtins.readFile ./config/lua/util.lua}
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

        # Theming
        (mkLuaPlugin catppuccin-nvim ./config/lua/catppuccin-config.lua)

        # Smooth scrolling
        vim-smoothie

        # Startup dashboard
        (mkLuaPlugin alpha-nvim ./config/lua/alpha-config.lua)

        # Keybindings window
        (mkLuaPlugin which-key-nvim ./config/lua/which-key-config.lua)

        # Syntax highlighting
        (mkLuaPlugin nvim-treesitter.withAllGrammars ./config/lua/treesitter-config.lua)
        (mkLuaPlugin nvim-treesitter-context ./config/lua/treesitter-context-config.lua)
        (mkLuaPlugin nvim-treesitter-textobjects ./config/lua/treesitter-textobjects-config.lua)

        # Status line
        (mkLuaPlugin heirline-nvim ./config/lua/heirline-config.lua)

        # File Tree
        (mkLuaPlugin nvim-tree-lua ./config/lua/nvim-tree-config.lua)
        nvim-web-devicons

        # Indent lines
        (mkLuaPlugin indent-blankline-nvim ./config/lua/indent-blankline-config.lua)

        # Auto close
        (mkLuaPlugin nvim-autopairs ./config/lua/autopairs-config.lua)

        # Completions
        (mkLuaPlugin blink-cmp ./config/lua/blink-config.lua)

        # LSP
        (mkLuaPlugin nvim-lspconfig ./config/lua/lsp-config.lua)
        nvim-lsp-ts-utils
        none-ls-nvim # Mostly for linting
        vim-illuminate # Highlight selected symbol

        # Better LSP references/definitions viewer
        (mkLuaPlugin glance-nvim ./config/lua/glance-config.lua)

        # Code outline sidebar
        (mkLuaPlugin outline-nvim ./config/lua/outline-config.lua)
        (mkLuaPlugin dropbar-nvim ./config/lua/dropbar-config.lua)

        # Diagnostics virtual text
        (mkLuaPlugin tiny-inline-diagnostic-nvim ./config/lua/tiny-inline-diagnostic-config.lua)

        # LSP status window
        (mkLuaPlugin fidget-nvim ./config/lua/fidget-config.lua)

        # Code actions sign
        (mkLuaPlugin nvim-lightbulb ./config/lua/lightbulb-config.lua)

        # Incremental rename
        (mkLuaPlugin inc-rename-nvim ./config/lua/inc-rename-config.lua)

        # Rainbow brackets
        (mkLuaPlugin rainbow-delimiters-nvim ./config/lua/rainbow-config.lua)

        # Fuzzy finder window
        (mkLuaPlugin telescope-nvim ./config/lua/telescope-config.lua)

        # Diagnostics window
        (mkLuaPlugin trouble-nvim ./config/lua/trouble-config.lua)

        # Better native input/select windows
        (mkLuaPlugin dressing-nvim ./config/lua/dressing-config.lua)

        # Tabs
        (mkLuaPlugin bufferline-nvim ./config/lua/bufferline-config.lua)

        # Git info
        (mkLuaPlugin gitsigns-nvim ./config/lua/gitsigns-config.lua)

        # Peek line search
        (mkLuaPlugin numb-nvim ./config/lua/numb-config.lua)

        # Fast navigation
        (mkLuaPlugin flash-nvim ./config/lua/flash-config.lua)

        # Debug adapter protocol
        (mkLuaPluginWithVars nvim-dap ./config/lua/dap-config.lua {
          python_debug_home = "${python-debug}";
        })
        telescope-dap-nvim
        nvim-dap-ui
        nvim-dap-virtual-text

        # Code Action
        tiny-code-action-nvim

        # Notify window
        (mkLuaPlugin nvim-notify ./config/lua/notify-config.lua)

        # Commenting
        (mkLuaPlugin comment-nvim ./config/lua/comment-config.lua)

        # Surround text objects
        (mkLuaPlugin nvim-surround ./config/lua/surround-config.lua)

        # Hover documentation
        (mkLuaPlugin hover-nvim ./config/lua/hover-config.lua)
      ] ++ lib.optionals cfg.includeAI [
        # AI
        (mkLuaPlugin claudecode-nvim ./config/lua/claude-code-config.lua)
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
        expert
        # Flix
        flix
        # Gleam
        gleam
        # Harper
        harper
        # Haskell
        stable.haskellPackages.haskell-language-server
        # Kotlin
        kotlin-lsp
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
        # Typst
        tinymist
        # Web (ESLint, HTML, CSS, JSON)
        nodePackages.vscode-langservers-extracted
        # Telescope tools
        ripgrep
        fd
      ] ++ lib.optionals cfg.includeAI [
        # AI
        claude-code
      ];
    };
  };
}
