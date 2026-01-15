# Common MCP server definitions shared across all AI tools
# Each tool transforms these to its specific format via lib.nix
{
  context7 = {
    url = "https://mcp.context7.com/mcp";
    transport = "http";
  };
  deepwiki = {
    url = "https://mcp.deepwiki.com/mcp";
    transport = "http";
  };
  sequential-thinking = {
    url = "https://remote.mcpservers.org/sequentialthinking/mcp";
    transport = "http";
  };
}
