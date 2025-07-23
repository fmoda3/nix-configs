{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.my-home;

  all-nerd-fonts = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  # Wrap github-mcp-server to give it an environment variable with our credential
  github-mcp-server-wrapped = with pkgs; writeShellScriptBin "github-mcp-server" (
    let
      envVars =
        if cfg.isWork then ''
          export GITHUB_PERSONAL_ACCESS_TOKEN="$(${coreutils}/bin/cat ${config.age.secrets."work_github_key".path})"
          export GITHUB_HOST="https://github.toasttab.com"
        '' else ''
          export GITHUB_PERSONAL_ACCESS_TOKEN="$(${coreutils}/bin/cat ${config.age.secrets."personal_github_key".path})"
        '';
    in
    ''
      ${envVars}
      exec ${mcp.github}/bin/github-mcp-server "$@"
    ''
  );

  # Build up list of claude code tools, to make sure they are available to claude
  claude-code-tools = with pkgs; lib.makeBinPath [
    ripgrep # Claude really likes to use ripgrep
    # MCP servers
    mcp.context7
    github-mcp-server-wrapped
    mcp.sequential-thinking
  ];

  # Make sure tools that are only meant for claude code, are applied to it's path
  claude-code-wrapped = with pkgs; writeShellScriptBin "claude" ''
    export PATH="${claude-code-tools}:$PATH"
    exec ${claude-code}/bin/claude "$@"
  '';
in
{

  imports = [
    # ./kitty
    ./zsh
    ./starship
    ./git
    ./nvim
    ./tmux
    ./direnv
    ./games
    ./gh
    ./bat
    ./btop
    ./yazi
    ./fzf
    ./zoxide
    ./eza
    ./lazygit
    ./secrets
  ];

  options.my-home = {
    includeFonts = lib.mkEnableOption "fonts";
    useNeovim = lib.mkEnableOption "neovim";
    isWork = lib.mkEnableOption "work profile";
    includeGames = lib.mkEnableOption "games";
  };

  config = {
    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    home = {
      sessionVariables = {
        EDITOR = "vim";
        VISUAL = "vim";
        PAGER = "less";
      };

      packages = with pkgs; let
        commonPackages = [
          # command line utilities
          ack
          curl
          htop
          neofetch
          tldr
          wget
          comma
          nix-cleanup
          aider-chat
          claude-code-wrapped
          ccusage
          nh
          procs
          dust
          gping
          tokei
          duf
        ];
        fontPackages = [
          # Fonts
          # cozette
          scientifica
          monocraft
        ] ++ all-nerd-fonts;
        vimPackage = [ vim ];
        workPackages = [
          # Work packages
          postgresql
          awscli2
          toast.oktoast
          toast.toast-services
          heroku
          colima
          docker
          docker-compose
          docker-credential-helpers
          android-tools
          autossh
          gh
        ];
      in
      commonPackages
      ++ (lib.optionals cfg.includeFonts fontPackages)
      ++ (lib.optionals (!cfg.useNeovim) vimPackage)
      ++ (lib.optionals cfg.isWork workPackages);
    };

    fonts.fontconfig.enable = cfg.includeFonts;

    programs.nix-index.enable = true;

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home.stateVersion = "21.05";
  };

}
