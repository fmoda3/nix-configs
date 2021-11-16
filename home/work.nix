{ config, lib, pkgs, ... }: {
  programs.git = {
    userEmail = "frank@toasttab.com";
    userName = "Frank Moda";
  };
}
