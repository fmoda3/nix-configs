{ config, pkgs, ...}:
{
   fonts = {
     fontDir.enable = true;
     # fonts declared with home-manager
     # fonts = with pkgs; [
     #   nerdfonts
     # ];
   };   
}
