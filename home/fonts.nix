{ config, pkgs, ... }:
{

  home = {
    packages = with pkgs; [
      # Fonts
      nerdfonts
      cozette
      scientifica
    ];
  };

  fonts.fontconfig.enable = true;
  
}
