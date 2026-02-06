final: prev:
{
  # Adding packages here, makes them accessible from "pkgs"
  catppuccin = {
    bat = prev.callPackage ./catppuccin/bat { };
    btop = prev.callPackage ./catppuccin/btop { };
    yazi = prev.callPackage ./catppuccin/yazi { };
    zsh-syntax-highlighting = prev.callPackage ./catppuccin/zsh-syntax-highlighting { };
  };
  ccusage = prev.callPackage ./ccusage { };
  claude-code = prev.callPackage ./claude-code { };
  codex = prev.callPackage ./codex { };
  homebridge = prev.callPackage ./homebridge { };
  homebridge-config-ui-x = prev.callPackage ./homebridge-config-ui-x { };
  kotlin-lsp = prev.callPackage ./kotlin-lsp { };
  nix-cleanup = prev.callPackage ./nix-cleanup { };
  opencode = prev.callPackage ./opencode { };
  # python3Packages = prev.python3Packages // {
  #   toast-tools = prev.callPackage ./toast-tools { };
  # };
  toast = {
    oktoast = prev.callPackage ./toast/oktoast { };
    toast-services = prev.callPackage ./toast/toast-services { };
    bedrock-llm-proxy = prev.callPackage ./toast/bedrock-llm-proxy { };
  };
  vimPlugins = prev.vimPlugins // {
    claudecode-nvim = prev.callPackage ./vimPlugins/claudecode-nvim { };
    tiny-code-action-nvim = prev.callPackage ./vimPlugins/tiny-code-action-nvim { };
  };
}
