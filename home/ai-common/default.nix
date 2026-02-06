{ lib }:
{
  mcpServers = import ./mcp-servers.nix;
  agents = import ./agents.nix;
  commands = import ./commands.nix;
  skills = import ./skills.nix;
  memory = import ./memory.nix;
  rules = import ./rules.nix;
  output-styles = import ./output-styles.nix;
  lib = import ./lib.nix { inherit lib; };
}
