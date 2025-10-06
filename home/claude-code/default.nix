{ config, lib, ... }:
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
        AWS_REGION = "us-east-1";
        CLAUDE_CODE_USE_BEDROCK = "1";
        CLAUDE_CODE_ENABLE_TELEMETRY = "1";
        OTEL_METRICS_EXPORTER = "otlp";
        OTEL_LOGS_EXPORTER = "otlp";
        OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://otel-collector-alb-466535050.us-east-1.elb.amazonaws.com";
        OTEL_RESOURCE_ATTRIBUTES = "department=engineering,team.id=paas,user_email=frank@toasttab.com,cost_center=default,organization=default";
      };
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
