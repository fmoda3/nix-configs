{ config, pkgs, ...}:

{
   fonts = {
     enableFontDir = true;
     fonts = with pkgs; [
       nerdfonts
     ];
   };   
}
