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
       minimize-to-application = true;
       launchanim = true;
       show-process-indicators = true;
       tilesize = 48;
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
