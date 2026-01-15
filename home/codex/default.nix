{ lib, ... }:
let
  ai = import ../ai-common { inherit lib; };

  # Convert commands to home.file entries for ~/.codex/prompts/
  codexPromptFiles = lib.mapAttrs'
    (name: content: lib.nameValuePair ".codex/prompts/${name}.md" { text = content; })
    (ai.lib.toCodexPrompts ai.commands);

  # Convert skills to home.file entries for ~/.codex/skills/<name>/SKILL.md
  codexSkillFiles = lib.mapAttrs'
    (name: content: lib.nameValuePair ".codex/skills/${name}/SKILL.md" { text = content; })
    (ai.lib.toCodexSkills ai.skills);
in
{
  programs.codex = {
    enable = true;
    settings = {
      mcp_servers = ai.lib.toCodexMcpServers ai.mcpServers;
    };
    custom-instructions = ai.lib.getMemoryWithRules ai.memory ai.rules;
  };

  # Codex prompts and skills are placed as files
  home.file = codexPromptFiles // codexSkillFiles;
}
