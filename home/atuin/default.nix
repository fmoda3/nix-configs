{ pkgs, ... }:
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = false;
      update_check = false;
      theme.name = "catppuccin-frappe-blue";
    };
  };

  xdg.configFile."atuin/themes" = {
    source = "${pkgs.catppuccin.atuin}/themes/frappe";
    recursive = true;
  };
}
