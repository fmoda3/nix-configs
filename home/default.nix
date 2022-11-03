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
        httpie
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
      ];
    };

    fonts.fontconfig.enable = cfg.includeFonts;

    programs.git =
      if cfg.isWork then {
        userEmail = "frank@toasttab.com";
        userName = "Frank Moda";
      } else {
        userEmail = "fmoda3@mac.com";
        userName = "Frank Moda";
      };

    programs.zsh.sessionVariables = optionalAttrs cfg.isWork {
      TOAST_GIT = "/Users/frank/Development";
    };

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
