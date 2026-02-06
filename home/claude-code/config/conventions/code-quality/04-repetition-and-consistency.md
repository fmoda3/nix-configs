<!-- applicable_phases: diff_review, codebase_review, refactor_code -->

# Repetition & Consistency

Evaluate whether code follows DRY principles and maintains consistency.

**The core question**: Is this DRY and consistent? When the same logic, validation, or pattern appears in multiple places, bugs must be fixed everywhere -- and they won't be. When similar operations use different patterns, readers question whether the difference is meaningful.

**What to look for**:

- Duplicated code blocks that would require multi-location bug fixes
- Validation rules implemented multiple times
- Business rules scattered across locations
- Repeated boolean expressions
- Inconsistent error handling within a file or class

**The threshold**: Flag when duplication is unintentional and would require coordinated changes. Flag inconsistency when it creates confusion about whether the difference is meaningful. Intentional duplication for modularity or bounded context isolation is acceptable.

<design-mode>
Not applicable -- this group requires actual code to evaluate.
</design-mode>

<code-mode>
When evaluating actual code (Diff Review, Codebase Review, Refactor):

- Would fixing a bug require changing multiple locations?
- Are validation/business rules duplicated?
- Are similar operations handled inconsistently?
- Do repeated patterns need extraction?

Evidence format: Quote code with file:line showing the duplication/inconsistency.
</code-mode>

---

## 1. Duplication

<principle>
Code should have a single source of truth. When the same logic exists in multiple places, bugs must be fixed everywhere -- and they won't be.
</principle>

Detect: If I fixed a bug here, where else would I need to fix it?

<grep-hints>
Structural indicators (starting points, not definitive):
Identical multi-line blocks, similar function bodies, function names suggesting similar purpose across modules
</grep-hints>

<violations>
Illustrative patterns (not exhaustive -- similar violations exist):

[high] Direct duplication

- Same code block duplicated (3+ lines, logic not just boilerplate)
- Any logic that would require multi-location bug fixes

[medium] Near-duplication

- Copy-paste with minor variations

[low] Missed abstraction

- Common pattern not extracted to shared location
  </violations>

<exceptions>
Intentionally different logic serving different purposes. Test setup code. Generated/vendored code. Deliberate isolation for modularity. Similar code in different bounded contexts.
</exceptions>

<threshold>
Flag when bug fix would require changing multiple locations AND the duplication is unintentional.
</threshold>

## 2. Validation Scattering

<principle>
Validation rules should live in one place. When the same validation is implemented multiple times, implementations diverge -- and some will be wrong.
</principle>

Detect: Is this validation duplicated? Would changing the validation rule require updating multiple locations?

<grep-hints>
Pattern indicators (starting points, not definitive):
Repeated regex patterns, duplicate bounds checks, email/phone/format validation across locations
</grep-hints>

<violations>
Illustrative patterns (not exhaustive -- similar violations exist):

[high] Diverged validation

- Validation rules diverged between implementations
- Any validation requiring multi-location updates

[medium] Repeated validation

- Same validation repeated without shared implementation

[low] Defensive re-validation

- Defensive re-validation deeper in call chain
  </violations>

<exceptions>
Validation at trust boundaries. Defense-in-depth by design. Context-specific validation rules. Service boundary validation.
</exceptions>

<threshold>
Flag when identical validation appears 3+ times (file scope) or 5+ files (codebase scope) AND implementations have diverged or will diverge.
</threshold>

## 3. Business Rule Scattering

<principle>
Business rules should have a single source of truth. When the same decision is made in multiple places, they will eventually disagree.
</principle>

Detect: Where is the single source of truth for this rule? If the rule changes, how many places need updating?

<grep-hints>
Pattern indicators (starting points, not definitive):
Repeated conditional patterns, magic numbers in multiple places, pricing/permission/eligibility logic
</grep-hints>

<violations>
Illustrative patterns (not exhaustive -- similar violations exist):

[high] Scattered decisions

- Same business decision in multiple places that could diverge
- Any business rule without clear single source of truth

[medium] Mixed concerns

- Business logic mixed with infrastructure code

[low] Implicit rules

- Rules embedded in raw conditionals instead of named predicates
  </violations>

<exceptions>
Orchestration calling multiple rule checks. Rules intentionally duplicated for service isolation. Per-tenant/region rule variations. Caching of computed rules.
</exceptions>

<threshold>
Flag when same business decision is made in 2+ places (file scope) or 3+ files (codebase scope) AND they have diverged or could diverge independently.
</threshold>

## 4. Condition Pattern Repetition

<principle>
Repeated boolean expressions should be named predicates. When the same condition appears everywhere, changing it requires finding all occurrences.
</principle>

Detect: Should this condition be a named predicate? Does extracting it reduce the bug surface area?

<grep-hints>
Pattern indicators (starting points, not definitive):
Identical boolean expressions, repeated guard clauses, permission/feature-flag check patterns
</grep-hints>

<violations>
Illustrative patterns (not exhaustive -- similar violations exist):

[high] High-frequency repetition

- Identical condition in 3+ places (file) or 5+ files (codebase) (extracting reduces bug surface)
- Any condition requiring multi-location updates when logic changes

[medium] Pattern repetition

- Repeated feature flag conditions

[low] Guard repetition

- Same guard clause pattern across related functions
  </violations>

<exceptions>
Standard guard clauses (null checks, bounds checks). Framework-required patterns. Simple conditions that read clearly inline.
</exceptions>

<threshold>
Flag when identical condition appears 3+ times (file scope) or 5+ files (codebase scope) AND extracting to named predicate would reduce bug surface area.
</threshold>

## 5. Error Pattern Consistency (File Scope)

<principle>
Error handling should be consistent within an abstraction level. Mixed patterns create confusion about how errors propagate and should be handled.
</principle>

Detect: Is error handling consistent within this file or class? Would a caller know what to expect from similar operations?

<grep-hints>
Pattern indicators (starting points, not definitive):
Mixed exception/return-code patterns, inconsistent error message formats, varying error context
</grep-hints>

<violations>
Illustrative patterns (not exhaustive -- similar violations exist):

[high] Incompatible patterns

- Incompatible error patterns for similar operations within same class
- Any error handling creating caller confusion

[medium] Inconsistent hierarchy

- Inconsistent exception hierarchies within same abstraction level

[low] Missing convention

- No standard for error context/wrapping within file
  </violations>

<exceptions>
Different patterns for different abstraction levels (domain vs API vs infra). Wrapper functions translating between error styles. Legacy code under active migration.
</exceptions>

<threshold>
Flag when same class uses 2+ incompatible error patterns for similar operations AND no migration plan exists.
</threshold>
