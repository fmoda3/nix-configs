<!-- applicable_phases: design_review, codebase_review, refactor_design, refactor_code -->

# Module & Dependencies

Evaluate whether module boundaries are clean and architecture aligns with change patterns.

**The core question**: Are boundaries clean? Modules should have clear boundaries with minimal coupling. Architecture should align with how features actually change. When changes ripple across unrelated modules or require touching many components, the boundaries are wrong.

**What to look for**:

- Circular dependencies
- Layer violations (domain importing infrastructure)
- Wrong component boundaries (features awkwardly split)
- Architecture forcing cross-cutting changes for single-domain features

**The threshold**: Flag when dependencies cause compilation issues or domain corruption. Flag when adding a feature requires touching many unrelated components. This is inherently about relationships between files and modules, not local code patterns.

<design-mode>
When evaluating Code Intent (Design Review phase):

- Does the proposed design create circular dependencies?
- Does it violate layer boundaries?
- Would implementing this feature require touching many components?

Evidence format: Quote the Code Intent description showing boundary issue.
</design-mode>

<code-mode>
When evaluating actual code (Codebase Review, Refactor):

- Do import graphs show circular dependencies?
- Are there layer violations in actual imports?
- Are features split across many loosely related components?

Evidence format: Quote import statements or describe dependency structure showing the issue.
</code-mode>

---

## 1. Module Structure

<principle>
Modules should have clear boundaries with minimal coupling. When changes ripple across unrelated modules, the boundaries are wrong.
</principle>

Detect: Do changes ripple to unrelated modules? Can a module be modified without understanding its dependents?

<grep-hints>
Structural indicators (starting points, not definitive):
Import graphs, dependency declarations, module boundaries
</grep-hints>

<violations>
Illustrative patterns (not exhaustive -- similar violations exist):

[high] Structural violations

- Circular dependencies (e.g., A imports B imports A)
- Layer violations (e.g., domain importing infrastructure)
- Any dependency causing compilation order issues or domain corruption

[medium] Cohesion problems

- Wrong cohesion (unrelated things grouped in same module)
- Missing facades (module internals exposed directly)

[low] Scope creep

- God modules (too many responsibilities in one module)
  </violations>

<exceptions>
Circular deps within same bounded context. Infrastructure adapters importing domain. Shared kernel patterns.
</exceptions>

<threshold>
Flag when dependency causes compilation order issues OR when layer violation allows infrastructure to corrupt domain.
</threshold>

## 2. Architecture

<principle>
Architecture should align with change patterns. When adding a feature requires touching many unrelated components, the architecture fights the domain.
</principle>

Detect: Would adding a feature require touching many components? Do cross-cutting changes indicate misaligned boundaries?

<grep-hints>
Structural indicators (starting points, not definitive):
Component boundaries, service interfaces, configuration locations
</grep-hints>

<violations>
Illustrative patterns (not exhaustive -- similar violations exist):

[high] Boundary misalignment

- Wrong component boundaries (features awkwardly split)
- Single points of failure (no fallback, no retry paths)
- Any architecture forcing cross-cutting changes for single-domain features

[medium] Scaling issues

- Scaling bottlenecks (synchronous where async needed)
- Monolith patterns in distributed code (or vice versa)

[low] Missing structure

- Missing abstraction layers (everything directly coupled)
- Configuration scattered (no central policy, settings in many places)
  </violations>

<exceptions>
Intentional coupling for simplicity. Early-stage monolith. Bounded contexts with shared kernel.
</exceptions>

<threshold>
Flag when architecture forces cross-cutting changes for single-domain features.
</threshold>
