{ pkgs, ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "catppuccin-frappe";
    };
  };

  xdg.configFile."btop/themes/catppuccin-frappe.theme".source =
    "${pkgs.catppuccin.btop}/themes/catppuccin_frappe.theme";
}
