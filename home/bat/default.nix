{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
    config = {
      theme = "catppuccin-frappe";
    };
    extraPackages = with pkgs.stable.bat-extras; [ batdiff batman batgrep batwatch ];
    themes = {
      catppuccin-frappe = {
        src = pkgs.catppuccin.bat;
        file = "themes/Catppuccin Frappe.tmTheme";
      };
      catppuccin-latte = {
        src = pkgs.catppuccin.bat;
        file = "themes/Catppuccin Latte.tmTheme";
      };
      catppuccin-macchiato = {
        src = pkgs.catppuccin.bat;
        file = "themes/Catppuccin Macchiato.tmTheme";
      };
      catppuccin-mocha = {
        src = pkgs.catppuccin.bat;
        file = "themes/Catppuccin Mocha.tmTheme";
      };
    };
  };
}
