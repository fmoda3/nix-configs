{ config, pkgs, ... }:
let
  vimSettings = builtins.readFile ../settings.vim;
in {
  imports = [ ../common.nix ];

  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
        # theming
        nord-vim
    ];

    extraConfig = ''
      ${builtins.replaceStrings ["THEME" "LIGHT_DARK"] ["nord" "dark"] vimSettings}
    '';
  };
}
