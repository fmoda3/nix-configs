{ config, lib, pkgs, ... }: {
  programs.git = {
    userEmail = "frank@toasttab.com";
    userName = "Frank Moda";
  };

  home = {
    packages = [
      pkgs.awscli
      pkgs.oktoast
      pkgs.pizzabox
    ];
  };
}
