{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.my-home;
in
{

  imports = [
    ./bat
    ./btop
    ./claude-code
    ./direnv
    ./eza
    ./fzf
    ./games
    ./gh
    ./git
    ./jq
    # ./kitty
    ./lazygit
    ./nh
    ./nvim
    ./secrets
    ./starship
    ./tmux
    ./yazi
    ./zoxide
    ./zsh
  ];

  options.my-home = {
    includeFonts = lib.mkEnableOption "fonts";
    useNeovim = lib.mkEnableOption "neovim";
    isWork = lib.mkEnableOption "work profile";
    includeGames = lib.mkEnableOption "games";
    flake = lib.mkOption {
      description = "Flake string to use for nh";
      default = "";
      type = types.str;
    };
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
          nerd-fonts.fira-code
          nerd-fonts.fira-mono
          nerd-fonts.inconsolata
          nerd-fonts.iosevka
          nerd-fonts.iosevka-term
          nerd-fonts.iosevka-term-slab
          nerd-fonts.monaspace
          nerd-fonts.terminess-ttf
        ];
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
