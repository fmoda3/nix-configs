{ config, pkgs, ... }:
let
  vimSettings = builtins.readFile ../settings.vim;
in {
  imports = [ ../common.nix ];

  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
        # theming
        vim-one
    ];

    extraConfig = ''
      ${builtins.replaceStrings ["THEME" "LIGHT_DARK"] ["one" "dark"] vimSettings}
    '';
  };
}
