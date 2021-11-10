{ config, pkgs, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    sessionVariables = {
      EDITOR = "vim";
      VISUAL = "vim";
      PAGER  = "less";
    };

    packages = with pkgs; [
      # command line utilities
      curl
      htop
      httpie
      neofetch
      wget

      # Fonts
      pkgs.nerdfonts
    ];
  };

  fonts.fontconfig.enable = true;

  imports = [
    ./kitty
    ./zsh
    ./git
    ./vim
    ./tmux
    ./direnv
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";
}
