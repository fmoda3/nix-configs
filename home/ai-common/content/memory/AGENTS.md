# Claude Code Guidelines

## Core Architecture: Functional Core, Imperative Shell (FCIS)

**Primary Pattern**: Separate pure functions (core) from side effects (shell).

### Essential Principles

1. **Pure Functional Core**
   - No I/O, mutations, or side effects
   - Deterministic functions only
   - Easy to test and reason about

2. **Imperative Shell**
   - Handles all I/O (API calls, database, file system)
   - Minimal logic, mostly orchestration
   - Calls core functions with data

3. **Make Invalid States Unrepresentable**
   - Use sum types/unions for mutually exclusive states
   - Use product types/records for required combinations
   - Fail fast at boundaries with validation

## Data Modeling

- **Sum Types**: `type Status = Loading | Success | Error`
- **Product Types**: Required fields grouped together
- **State Machines**: Model business logic as explicit states and transitions
- **Validation**: Transform untrusted input → validated domain types at boundaries

## Testing Strategy

- **Core**: Unit tests with property-based testing when possible
- **Shell**: Integration tests focusing on I/O correctness
- **Boundaries**: Contract tests for external interfaces

## Code Organization

```
src/
├── core/           # Pure business logic
├── shell/          # I/O operations
├── types/          # Domain models
└── boundaries/     # Input validation & transformation
```

## Key Patterns

- **Repository Pattern**: Shell handles data access, core operates on domain types
- **Command/Query Separation**: Distinguish data changes from data reads
- **Result Types**: Handle errors explicitly without exceptions in core
- **Dependency Injection**: Shell provides dependencies to core

## Security & Performance

- **Input Validation**: Always at shell boundaries before entering core
- **Least Privilege**: Core functions only get data they need
- **Immutability**: Prefer immutable data structures
- **Lazy Evaluation**: Compute only when needed

---

**Implementation Notes**:
- Apply these patterns regardless of language
- Start with types and data models first
- Keep core functions small and composable
- Test core logic extensively, shell integration carefully
