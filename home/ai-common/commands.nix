# Commands/prompts structure - maps to commands (claude-code, opencode) or custom_prompts (codex)
{
  packages = {
    check_updates = {
      description = "Check for package updates";
      bodyFile = ./content/commands/packages/check_updates.md;
    };
  };

  tasks = {
    create_plan = {
      description = "Create a plan";
      bodyFile = ./content/commands/tasks/create_plan.md;
    };

    create_plan_with_tdd = {
      description = "Create a plan with TDD";
      bodyFile = ./content/commands/tasks/create_plan_with_tdd.md;
    };

    create_spec = {
      description = "Create a specification";
      bodyFile = ./content/commands/tasks/create_spec.md;
    };

    idea = {
      description = "Idea Honing";
      bodyFile = ./content/commands/tasks/idea.md;
    };

    run_plan = {
      description = "Run a plan";
      bodyFile = ./content/commands/tasks/run_plan.md;
    };
  };
}
