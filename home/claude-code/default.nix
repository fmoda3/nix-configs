{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.my-home;

  # Wrap github-mcp-server to give it an environment variable with our credential
  github-mcp-server-wrapped = with pkgs; writeShellScriptBin "github-mcp-server" (
    let
      envVars =
        if cfg.isWork then ''
          export GITHUB_PERSONAL_ACCESS_TOKEN="$(${coreutils}/bin/cat ${config.age.secrets."work_github_key".path})"
          export GITHUB_HOST="https://github.toasttab.com"
        '' else ''
          export GITHUB_PERSONAL_ACCESS_TOKEN="$(${coreutils}/bin/cat ${config.age.secrets."personal_github_key".path})"
        '';
    in
    ''
      ${envVars}
      exec ${mcp.github}/bin/github-mcp-server "$@"
    ''
  );

  # Build up list of claude code tools, to make sure they are available to claude
  claude-code-tools = with pkgs; lib.makeBinPath [
    ripgrep # Claude really likes to use ripgrep
    # MCP servers
    github-mcp-server-wrapped
    playwright-mcp
  ];

  # Make sure tools that are only meant for claude code, are applied to it's path
  claude-code-wrapped = with pkgs; writeShellScriptBin "claude" ''
    export PATH="${claude-code-tools}:$PATH"
    exec ${claude-code}/bin/claude "$@"
  '';
in
{
  config = {
    home = {
      packages = with pkgs; [
        claude-code-wrapped
        ccusage
      ];

      # Link Claude Code configuration files
      file = {
        ".claude/CLAUDE.md".source = ./config/CLAUDE.md;
        ".claude/settings.json".source = ./config/settings.json;
        ".claude/commands".source = ./config/commands;
      };
    };
  };
}
