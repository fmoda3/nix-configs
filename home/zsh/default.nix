{ config, pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";

    historySubstringSearch.enable = true;
    history = {
      expireDuplicatesFirst = true;
      extended = true;
      findNoDups = true;
      ignoreAllDups = true;
      saveNoDups = true;
    };

    sessionVariables = import ./env.nix { inherit config pkgs lib; };

    shellAliases = import ./aliases.nix;

    shellGlobalAliases = {
      "--help" = "--help 2>&1 | bat --language=help --style=plain";
    };

    initContent = ''
      eval "$(direnv hook zsh)"
      eval "$(batman --export-env)"
      path+="/opt/homebrew/bin"

      source ${pkgs.catppuccin.zsh-syntax-highlighting}/themes/catppuccin_frappe-zsh-syntax-highlighting.zsh

      ${builtins.readFile ./init.zsh}
    '';
  };
}
