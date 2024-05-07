{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.my-home;
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

      packages = with pkgs; [
        # command line utilities
        ack
        curl
        htop
        neofetch
        tldr
        wget
        comma
        nix-cleanup
      ] ++ optionals cfg.includeFonts [
        # Fonts
        nerdfonts
        cozette
        scientifica
        monocraft
      ] ++ optionals (!cfg.useNeovim) [
        # Add vim if not setting up neovim
        vim
      ] ++ optionals cfg.isWork [
        # Work packages
        postgresql
        awscli2
        oktoast
        toast-services
        pizzabox
        heroku
        colima
        docker
        docker-compose
        docker-credential-helpers
        android-tools
        autossh
        gh
      ];
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
