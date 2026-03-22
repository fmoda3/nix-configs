{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
  };

  xdg.configFile = {
    "yazi/theme.toml".source =
      "${pkgs.catppuccin.yazi}/frappe/catppuccin-frappe-blue.toml";

    "yazi/Catppuccin-frappe.tmTheme".source =
      "${pkgs.catppuccin.bat}/Catppuccin Frappe.tmTheme";
  };
}
