# Unified agent structure - tools use only fields they support
{
  architect = {
    name = "architect";
    description = ''
      Understands architecture, project conventions, and quality designs
    '';
    bodyFile = ./content/agents/architect.md;
    model = "opus";
    # claude-code specific
    color = "purple";
  };

  debugger = {
    name = "debugger";
    description = ''
      Analyzes bugs through systematic evidence gathering - use for complex debugging
    '';
    bodyFile = ./content/agents/debugger.md;
    model = "sonnet";
    # claude-code specific
    color = "cyan";
  };

  developer = {
    name = "developer";
    description = ''
      Implements your specs with tests - delegate for writing code
    '';
    bodyFile = ./content/agents/developer.md;
    model = "sonnet";
    # claude-code specific
    color = "blue";
  };

  quality-reviewer = {
    name = "quality-reviewer";
    description = ''
      Reviews code and plans for production risks, project conformance, and structural quality
    '';
    bodyFile = ./content/agents/quality-reviewer.md;
    model = "sonnet";
    # claude-code specific
    color = "orange";
  };

  technical-writer = {
    name = "technical-writer";
    description = ''
      Creates documentation optimized for LLM consumption
    '';
    bodyFile = ./content/agents/technical-writer.md;
    model = "sonnet";
    # claude-code specific
    color = "green";
  };
}
