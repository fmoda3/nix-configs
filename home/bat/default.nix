{ pkgs, ... }:
let
  catppuccin-bat = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "699f60fc8ec434574ca7451b444b880430319941";
    sha256 = "sha256-6fWoCH90IGumAMc4buLRWL0N61op+AuMNN9CAR9/OdI=";
  };
in
{
  programs.bat = {
    enable = true;
    config = {
      theme = "catppuccin-frappe";
    };
    themes = {
      catppuccin-frappe = {
        src = catppuccin-bat;
        file = "themes/Catppuccin Frappe.tmTheme";
      };
      catppuccin-latte = {
        src = catppuccin-bat;
        file = "themes/Catppuccin Latte.tmTheme";
      };
      catppuccin-macchiato = {
        src = catppuccin-bat;
        file = "themes/Catppuccin Macchiato.tmTheme";
      };
      catppuccin-mocha = {
        src = catppuccin-bat;
        file = "themes/Catppuccin Mocha.tmTheme";
      };
    };
  };
}
