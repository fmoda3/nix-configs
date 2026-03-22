{ pkgs, ... }:
{
  imports = [
    ./aliases.nix
    ./env.nix
  ];

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # Catppuccin Frappe theme
      fish_config theme choose catppuccin-frappe

      # Batman (bat-powered man pages)
      eval (batman --export-env)

      # Add Homebrew to path
      fish_add_path /opt/homebrew/bin

      # Disable fish greeting
      set -g fish_greeting
    '';

    functions = {
      # Help wrapper to pipe through bat (replaces zsh global alias)
      help = {
        description = "Show command help through bat";
        body = "$argv --help 2>&1 | bat --language=help --style=plain";
      };

      # mkdir and cd into it
      mkcd = {
        description = "Create directory and cd into it";
        body = "mkdir -p $argv[1] && cd $argv[1]";
      };
    };
  };

  xdg.configFile."fish/themes/catppuccin-frappe.theme".source =
    "${pkgs.catppuccin.fish}/themes/catppuccin-frappe.theme";
}
