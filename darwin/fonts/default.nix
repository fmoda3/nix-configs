{ config, pkgs, ...}:

{
   fonts = {
     enableFontDir = true;
     fonts = with pkgs; [
       fira-code
       fira-code-symbols
       font-awesome
       nerdfonts
     ];
   };   
}
