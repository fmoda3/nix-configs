{ config, lib, pkgs, ... }:
let
  cfg = config.my-home;
  ai = import ../ai-common { inherit lib; };

  commonEnv = {
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
  };

  # Work-specific MCP servers
  workMcpServers = {
    atlassian = {
      type = "sse";
      url = "https://mcp.atlassian.com/v1/sse";
    };
    buffet = {
      command = "npx";
      args = [
        "--registry=https://artifactory.eng.toasttab.com/artifactory/api/npm/toast_npm/"
        "@toasttab/buffet-mcp-server@next"
      ];
    };
    figma = {
      type = "http";
      url = "http://127.0.0.1:3845/mcp";
    };
  };

  # Convert styles to home.file entries for ~/.claude/output-styles/<name>.md
  claudeCodeStyleFiles = lib.mapAttrs'
    (name: content: lib.nameValuePair ".claude/output-styles/${name}.md" { text = content; })
    (ai.lib.toClaudeCodeOutputStyles ai.output-styles);
in
{
  programs.claude-code = {
    enable = cfg.includeAI;
    settings = {
      hooks = {
        Stop = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "afplay /System/Library/Sounds/Funk.aiff";
              }
            ];
          }
        ];
        Notification = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "afplay /System/Library/Sounds/Funk.aiff";
              }
            ];
          }
        ];
      };
      statusLine = {
        type = "command";
        command = "~/.claude/statusline.sh";
      };
    } // lib.optionalAttrs (!cfg.isWork) {
      env = commonEnv // {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
      teammateMode = "tmux";
    } // lib.optionalAttrs cfg.isWork {
      env = commonEnv // {
        CLAUDE_CODE_USE_BEDROCK = "1";
        CLAUDE_CODE_SKIP_BEDROCK_AUTH = "1";
        ANTHROPIC_BEDROCK_BASE_URL = "https://llm-proxy.prod-build.int.toasttab.com/bedrock";
        ANTHROPIC_DEFAULT_OPUS_MODEL = "global.anthropic.claude-opus-4-6-v1";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "global.anthropic.claude-sonnet-4-5-20250929-v1:0";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "global.anthropic.claude-haiku-4-5-20251001-v1:0";
        CLAUDE_CODE_ENABLE_TELEMETRY = "1";
        OTEL_METRICS_EXPORTER = "otlp";
        OTEL_LOGS_EXPORTER = "otlp";
        OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
        OTEL_EXPORTER_OTLP_ENDPOINT = "https://bedrock-otel-collector.build.eng.toasttab.com";
        OTEL_RESOURCE_ATTRIBUTES = "department=engineering,team.id=paas,user_email=frank@toasttab.com,cost_center=default,organization=default";
      };
      apiKeyHelper = "${pkgs.toast.bedrock-llm-proxy}/bin/toastApiKeyHelper";
      extraKnownMarketplaces = {
        "toast-marketplace" = {
          source = {
            source = "git";
            url = "git@github.toasttab.com:toasttab/claude-marketplace.git";
          };
        };
      };
      enabledPlugins = {
        "toast-developer@toast-marketplace" = true;
        "toast-backend-development@toast-marketplace" = true;
      };
    };

    # From common config via transformation functions
    mcpServers = ai.lib.toClaudeCodeMcpServers ai.mcpServers
      // lib.optionalAttrs cfg.isWork workMcpServers;
    agents = ai.lib.toClaudeCodeAgents ai.agents;
    commands = ai.lib.toClaudeCodeCommands ai.commands;
    skills = ai.lib.toClaudeCodeSkills ai.skills;
    rules = ai.lib.toClaudeCodeRules ai.rules;
    memory.source = ai.memory.source;
  };

  home = {
    file = {
      ".claude/statusline.sh" = {
        source = ./config/statusline.sh;
        executable = true;
      };
    } // claudeCodeStyleFiles;
  };
}
