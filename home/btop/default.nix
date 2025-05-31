{ pkgs, ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "catppuccin-frappe";
    };
    themes = {
      catppuccin-frappe = builtins.readFile "${pkgs.catppuccin-btop}/themes/catppuccin_frappe.theme";
    };
  };
}
