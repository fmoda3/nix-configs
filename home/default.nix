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
  ];

  options.my-home = {
    includeFonts = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Include my favorite fonts
      '';
    };

    useNeovim = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Include neovim with my customizations
      '';
    };

    isWork = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether this is a work profile
      '';
    };

    includeGames = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Include games
      '';
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

      packages = with pkgs; [
        # command line utilities
        ack
        curl
        htop
        neofetch
        tldr
        wget
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
      ];
    };

    fonts.fontconfig.enable = cfg.includeFonts;

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
