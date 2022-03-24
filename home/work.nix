{ config, lib, pkgs, ... }: {
  programs.git = {
    userEmail = "frank@toasttab.com";
    userName = "Frank Moda";
  };

  home = {
    packages = with pkgs; [
      awscli
      oktoast
      pizzabox
      heroku
    ];
  };

  programs.zsh.sessionVariables = {
    TOAST_GIT = "/Users/frank/Development";
  };
}
