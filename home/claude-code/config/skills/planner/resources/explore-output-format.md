# Exploration Output Schema

Structure exploration findings using this XML format. Each section maps to a
specific planning consumer step.

```xml
<exploration_output task="[brief task description]">

  <approach_inputs>
    <!-- For Step 3: Approach Generation -->
    <!-- What patterns exist? What constraints apply? What favors which approach? -->

    <patterns>
      <pattern name="[name]" location="[file:line]">
        [How it works. Constraints it imposes. Why it matters for approach selection.]
      </pattern>
    </patterns>

    <constraints>
      <constraint impact="[which approach it favors]">
        [What the constraint is and why it affects approach choice]
      </constraint>
    </constraints>
  </approach_inputs>

  <assumption_inputs>
    <!-- For Step 4: Assumption Surfacing -->
    <!-- What's ambiguous? What policies are implicit? What needs user confirmation? -->

    <ambiguities>
      <ambiguity needs_confirmation="true|false">
        [What's unclear. Options available. Why confirmation needed.]
      </ambiguity>
    </ambiguities>

    <implicit_policies>
      <policy area="[timeout|retry|lifecycle|etc]">
        [Current behavior observed. Whether explicit choice needed.]
      </policy>
    </implicit_policies>
  </assumption_inputs>

  <milestone_inputs>
    <!-- For Step 5: Milestone Planning -->
    <!-- What files? What can fail? What's testable? -->

    <files>
      <file path="[exact path]" purpose="[why modify]">
        [Dependencies. Role in system. Key functions/structures.]
      </file>
    </files>

    <failure_modes>
      <failure risk="[high|medium|low]">
        [What can fail. Impact. Mitigation approach.]
      </failure>
    </failure_modes>

    <test_coverage>
      <tests path="[test file]" type="[unit|integration|property]">
        [What behaviors are tested. Patterns used. Reusable fixtures.]
      </tests>
      <gaps>
        [What's NOT tested that acceptance criteria will need.]
      </gaps>
    </test_coverage>
  </milestone_inputs>

</exploration_output>
```

## Section Guidelines

### approach_inputs (~500 tokens)

Include patterns and constraints that affect approach selection:

- How existing code handles similar concerns
- Architectural constraints (dependencies, interfaces, conventions)
- Complexity factors for different implementation strategies

### assumption_inputs (~500 tokens)

Include ambiguities and implicit policies:

- Things that require user confirmation before proceeding
- Policy defaults observed (timeouts, retries, error handling)
- Architectural choices with multiple valid options

### milestone_inputs (~500 tokens)

Include information for milestone planning:

- Files to modify with their purposes and dependencies
- Failure modes and risks to mitigate
- Testable behaviors and existing test coverage
