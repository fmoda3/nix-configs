final: prev:
{
  # Adding packages here, makes them accessible from "pkgs"
  catppuccin-bat = prev.callPackage ./catppuccin-bat { };
  catppuccin-btop = prev.callPackage ./catppuccin-btop { };
  catppuccin-yazi = prev.callPackage ./catppuccin-yazi { };
  catppuccin-zsh-syntax-highlighting = prev.callPackage ./catppuccin-zsh-syntax-highlighting { };
  claude-code = prev.callPackage ./claude-code { };
  homebridge = prev.callPackage ./homebridge { };
  homebridge-config-ui-x = prev.callPackage ./homebridge-config-ui-x { };
  kotlin-lsp = prev.callPackage ./kotlin-lsp { };
  nix-cleanup = prev.callPackage ./nix-cleanup { };
  oktoast = prev.callPackage ./oktoast { };
  # python3Packages = prev.python3Packages // {
  #   toast-tools = prev.callPackage ./toast-tools { };
  # };
  toast-services = prev.callPackage ./toast-services { };
  vimPlugins = prev.vimPlugins // {
    tiny-code-action-nvim = prev.callPackage ./tiny-code-action-nvim { };
  };
}
