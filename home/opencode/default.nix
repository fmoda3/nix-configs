{ lib, config, ... }:
let
  ai = import ../ai-common { inherit lib; };
in
{
  programs.opencode = {
    enable = config.my-home.includeAI;
    settings = {
      autoupdate = false;
      theme = "system";
      mcp = ai.lib.toOpencodeMcp ai.mcpServers;
    };
    rules = ai.lib.getMemoryWithRules ai.memory ai.rules;
    agents = ai.lib.toOpencodeAgents ai.agents;
    commands = ai.lib.toOpencodeCommands ai.commands;
    skills = ai.lib.toOpencodeSkills ai.skills;
  };
}
