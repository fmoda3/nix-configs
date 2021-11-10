{ config, pkgs, ...}:
{
   fonts = {
     enableFontDir = true;
     # fonts declared with home-manager
     # fonts = with pkgs; [
     #   nerdfonts
     # ];
   };   
}
