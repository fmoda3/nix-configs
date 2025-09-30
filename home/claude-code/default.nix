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
in
{
  config = {
    home = {
      packages = with pkgs; [
        claude-code
        ccusage
        ripgrep # Claude really likes to use ripgrep
        # MCP servers
        github-mcp-server-wrapped
        playwright-mcp
      ];

      # Link Claude Code configuration files
      file = {
        ".claude/CLAUDE.md".source = ./config/CLAUDE.md;
        ".claude/settings.json".source = if cfg.isWork then ./config/settings-work.json else ./config/settings.json;
        ".claude/agents".source = ./config/agents;
        ".claude/commands".source = ./config/commands;
        ".claude/statusline.sh" = {
          source = ./config/statusline.sh;
          executable = true;
        };
      };
    };
  };
}
