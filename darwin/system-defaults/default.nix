{ config, pkgs, ...}:

{
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.defaults = {
     dock = {
       autohide = true;
       orientation = "bottom";
       showhidden = true;
       mineffect = "genie";
       launchanim = true;
       show-process-indicators = true;
       tilesize = 48;
       static-only = true;
       mru-spaces = false;
     };
     finder = {
       AppleShowAllExtensions = true;
       FXEnableExtensionChangeWarning = false;
       CreateDesktop = false; # disable desktop icons
     };
     NSGlobalDomain = {
       AppleInterfaceStyle = "Dark"; # set dark mode
     };
   };
  
}
