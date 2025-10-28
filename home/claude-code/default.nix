{ config, lib, pkgs, ... }:
let
  cfg = config.my-home;
in
{
  programs.claude-code = {
    enable = true;
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
    } // lib.optionalAttrs cfg.isWork {
      env = {
        CLAUDE_CODE_USE_BEDROCK = "1";
        CLAUDE_CODE_SKIP_BEDROCK_AUTH = "1";
        ANTHROPIC_BEDROCK_BASE_URL = "https://llm-proxy.prod-build.int.toasttab.com/bedrock";
        ANTHROPIC_MODEL = "global.anthropic.claude-sonnet-4-5-20250929-v1:0";
        CLAUDE_CODE_ENABLE_TELEMETRY = "1";
        OTEL_METRICS_EXPORTER = "otlp";
        OTEL_LOGS_EXPORTER = "otlp";
        OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
        OTEL_EXPORTER_OTLP_ENDPOINT = "https://bedrock-otel-collector.build.eng.toasttab.com";
        OTEL_RESOURCE_ATTRIBUTES = "department=engineering,team.id=paas,user_email=frank@toasttab.com,cost_center=default,organization=default";
      };
      apiKeyHelper = "${pkgs.toast.toastApiKeyHelper}/bin/toastApiKeyHelper";
    };
    memory.source = ./config/CLAUDE.md;
    agentsDir = ./config/agents;
    commandsDir = ./config/commands;
    mcpServers = {
      context7 = {
        type = "http";
        url = "https://mcp.context7.com/mcp";
      };
      deepwiki = {
        type = "http";
        url = "https://mcp.deepwiki.com/mcp";
      };
      sequential-thinking = {
        type = "http";
        url = "https://remote.mcpservers.org/sequentialthinking/mcp";
      };
    } // lib.optionalAttrs cfg.isWork {
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
    };
  };

  home = {
    file = {
      ".claude/statusline.sh" = {
        source = ./config/statusline.sh;
        executable = true;
      };
    };
  };
}
