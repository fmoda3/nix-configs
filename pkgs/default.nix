final: prev:
{
  # Adding packages here, makes them accessible from "pkgs"
  catppuccin = {
    atuin = prev.callPackage ./catppuccin/atuin { };
    bat = prev.callPackage ./catppuccin/bat { };
    btop = prev.callPackage ./catppuccin/btop { };
    yazi = prev.callPackage ./catppuccin/yazi { };
    fish = prev.callPackage ./catppuccin/fish { };
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
  pi-coding-agent = prev.callPackage ./pi-coding-agent { };
  piExtensions = {
    pi-ask-tool = prev.callPackage ./piExtensions/pi-ask-tool { };
    pi-context = prev.callPackage ./piExtensions/pi-context { };
    pi-direnv = prev.callPackage ./piExtensions/pi-direnv { };
    pi-ghostty = prev.callPackage ./piExtensions/pi-ghostty { };
    pi-mcp-adapter = prev.callPackage ./piExtensions/pi-mcp-adapter { };
    pi-notify = prev.callPackage ./piExtensions/pi-notify { };
    pi-plan = prev.callPackage ./piExtensions/pi-plan { };
    pi-powerline-footer = prev.callPackage ./piExtensions/pi-powerline-footer { };
    pi-processes = prev.callPackage ./piExtensions/pi-processes { };
    pi-sub-bar = prev.callPackage ./piExtensions/pi-sub-bar { };
    pi-subagents = prev.callPackage ./piExtensions/pi-subagents { };
    pi-teams = prev.callPackage ./piExtensions/pi-teams { };
  };
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
