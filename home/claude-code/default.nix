{ config, lib, pkgs, ... }:
let
  cfg = config.my-home;

  extraPackages = with pkgs; [
    # Bash
    bash-language-server
    # Elixir
    expert
    # Kotlin
    kotlin-lsp
    # Lua
    lua-language-server
    # Nix
    nixd
    # Python
    pyright
    python3
    # Typescript
    typescript-language-server
  ];

  wrappedClaude = pkgs.symlinkJoin {
    name = "claude-code-wrapped";
    paths = [ pkgs.claude-code ];
    buildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --prefix PATH : ${pkgs.lib.makeBinPath extraPackages} \
        --add-flags "--thinking-display summarized"
    '';
  };

  # COMMON
  commonEnv = {
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
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

  commonLspServers = {
    bash = {
      command = "bash-language-server";
      args = [ "start" ];
      extensionToLanguage = {
        ".sh" = "shellscript";
        ".bash" = "shellscript";
        ".bashrc" = "shellscript";
        ".bash_profile" = "shellscript";
        ".profile" = "shellscript";
      };
    };
    elixir = {
      command = "expert";
      args = [ "--stdio" ];
      extensionToLanguage = {
        ".ex" = "elixir";
        ".exs" = "elixir";
        ".eex" = "eex";
        ".leex" = "eex";
        ".heex" = "phoenix-heex";
        ".sface" = "surface";
        ".html.eex" = "html-eex";
        ".html.leex" = "html-eex";
      };
    };
    kotlin = {
      command = "kotlin-lsp";
      args = [ "--stdio" ];
      extensionToLanguage = {
        ".kt" = "kotlin";
        ".kts" = "kotlin";
      };
      startupTimeout = 120000;
    };
    lua = {
      command = "lua-language-server";
      extensionToLanguage = {
        ".lua" = "lua";
      };
    };
    nix = {
      command = "nixd";
      extensionToLanguage = {
        ".nix" = "nix";
      };
    };
    python = {
      command = "pyright-langserver";
      args = [ "--stdio" ];
      extensionToLanguage = {
        ".py" = "python";
        ".pyi" = "python";
      };
    };
    typescript = {
      command = "typescript-language-server";
      args = [ "--stdio" ];
      extensionToLanguage = {
        ".ts" = "typescript";
        ".tsx" = "typescriptreact";
        ".js" = "javascript";
        ".jsx" = "javascriptreact";
        ".mts" = "typescript";
        ".cts" = "typescript";
        ".mjs" = "javascript";
        ".cjs" = "javascript";
      };
    };
  };

  # WORK
  workEnv = commonEnv // {
    CLAUDE_CODE_USE_BEDROCK = "1";
    CLAUDE_CODE_SKIP_BEDROCK_AUTH = "1";
    ANTHROPIC_BEDROCK_BASE_URL = "https://llm-proxy.build.eng.toasttab.com/bedrock";
    ANTHROPIC_DEFAULT_OPUS_MODEL = "global.anthropic.claude-opus-4-7[1m]";
    ANTHROPIC_DEFAULT_SONNET_MODEL = "global.anthropic.claude-sonnet-4-6[1m]";
    ANTHROPIC_DEFAULT_HAIKU_MODEL = "global.anthropic.claude-haiku-4-5-20251001-v1:0";
    CLAUDE_CODE_SUBAGENT_MODEL = "global.anthropic.claude-sonnet-4-6";
    CLAUDE_CODE_ENABLE_TELEMETRY = "1";
    OTEL_METRICS_EXPORTER = "otlp";
    OTEL_LOGS_EXPORTER = "otlp";
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
    OTEL_EXPORTER_OTLP_ENDPOINT = "https://bedrock-otel-collector.build.eng.toasttab.com";
    OTEL_LOG_TOOL_DETAILS = "1";
    OTEL_METRICS_INCLUDE_SESSION_ID = "true";
    OTEL_RESOURCE_ATTRIBUTES = "department=engineering,team.id=paas,user_email=frank@toasttab.com,cost_center=default,organization=default";
  };

  workMcpServers = commonMcpServers // {
    atlassian = {
      type = "http";
      url = "https://mcp.atlassian.com/v1/mcp";
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
      teammateMode = "tmux";
      skipAutoPermissionPrompt = true;
      lspRecommendationDisabled = true;
      showThinkingSummaries = true;
    } // lib.optionalAttrs (!cfg.isWork) {
      env = commonEnv;
    } // lib.optionalAttrs cfg.isWork {
      env = workEnv;
      apiKeyHelper = "${pkgs.toast.bedrock-llm-proxy}/bin/toastApiKeyHelper";
      otelHeadersHelper = "${pkgs.toast.bedrock-llm-proxy}/bin/otelHeadersHelper";
      extraKnownMarketplaces = workKnownMarketplaces;
      enabledPlugins = workEnabledPlugins;
    };

    mcpServers = commonMcpServers // lib.optionalAttrs cfg.isWork workMcpServers;
    lspServers = commonLspServers;
    agentsDir = ./config/agents;
    commandsDir = ./config/commands;
    context = ./config/CLAUDE.md;
    skills = ./config/skills;
    outputStyles = {
      direct = ./config/output-styles/direct.md;
    };
  };

  home = {
    file = {
      ".claude/statusline.sh" = {
        source = ./config/statusline.sh;
        executable = true;
      };
      ".claude/conventions" = {
        source = ./config/conventions;
        recursive = true;
      };
      ".claude/themes" = {
        source = ./config/themes;
        recursive = true;
      };
    };
  };
}
