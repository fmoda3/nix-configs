{
  programs.codex = {
    enable = true;
    settings = {
      experimental_use_rmcp_client = true;
      mcp_servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };
        deepwiki = {
          url = "https://mcp.deepwiki.com/mcp";
        };
        sequential-thinking = {
          url = "https://remote.mcpservers.org/sequentialthinking/mcp";
        };
      };
    };
  };
}
