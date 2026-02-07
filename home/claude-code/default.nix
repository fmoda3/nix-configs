{ config, lib, pkgs, ... }:
let
  cfg = config.my-home;

  extraPackages = with pkgs; [
    python3
  ];

  wrappedClaude = pkgs.symlinkJoin {
    name = "claude-code-wrapped";
    paths = [ pkgs.claude-code ];
    buildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --prefix PATH : ${pkgs.lib.makeBinPath extraPackages}
    '';
  };

  # COMMON
  commonEnv = {
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
  };

  commonStatusLine = {
    type = "command";
    command = "~/.claude/statusline.sh";
  };

  commonHooks = {
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

  commonMcpServers = {
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
  };

  # PERSONAL
  personalEnv = commonEnv // {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
  };

  # WORK
  workEnv = commonEnv // {
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

  workMcpServers = commonMcpServers // {
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

  workKnownMarketplaces = {
    "toast-marketplace" = {
      source = {
        source = "git";
        url = "git@github.toasttab.com:toasttab/claude-marketplace.git";
      };
    };
  };

  workEnabledPlugins = {
    "toast-developer@toast-marketplace" = true;
    "toast-backend-development@toast-marketplace" = true;
  };
in
{
  programs.claude-code = {
    enable = cfg.includeAI;
    package = wrappedClaude;
    settings = {
      hooks = commonHooks;
      statusLine = commonStatusLine;
    } // lib.optionalAttrs (!cfg.isWork) {
      env = personalEnv;
      teammateMode = "tmux";
    } // lib.optionalAttrs cfg.isWork {
      env = workEnv;
      apiKeyHelper = "${pkgs.toast.bedrock-llm-proxy}/bin/toastApiKeyHelper";
      extraKnownMarketplaces = workKnownMarketplaces;
      enabledPlugins = workEnabledPlugins;
    };

    mcpServers = commonMcpServers // lib.optionalAttrs cfg.isWork workMcpServers;
    agentsDir = ./config/agents;
    commandsDir = ./config/commands;
    memory.source = ./config/CLAUDE.md;
    skillsDir = ./config/skills;
  };

  home = {
    file = {
      ".claude/statusline.sh" = {
        source = ./config/statusline.sh;
        executable = true;
      };
      ".claude/output-styles" = {
        source = ./config/output-styles;
        recursive = true;
      };
      ".claude/conventions" = {
        source = ./config/conventions;
        recursive = true;
      };
    };
  };
}
