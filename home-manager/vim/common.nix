{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
        # Basics
        vim-sensible
        vim-fugitive
        vim-surround
        vim-commentary
        vim-sneak
        vim-closetag
        vim-nix
        vim-polyglot
        lightline-vim
    ];
  };
}
