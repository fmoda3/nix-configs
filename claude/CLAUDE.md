# Claude Code Global Guidelines

My name is Frank.

This document serves as the table of contents for all Claude Code guidelines. Claude should read and follow all linked documents when working on any project.

## Architecture & Design Patterns

- [Functional Core, Imperative Shell](fcis-architecture.md) - **PRIMARY ARCHITECTURE PATTERN**
  - All projects must follow FCIS principles
  - Pure functional core with imperative shell for I/O
  - Making invalid states unrepresentable

## Language-Specific Guidelines

- [Kotlin Guidelines](kotlin-guidelines.md)
  - Coroutines best practices
  - Data class and sealed class patterns
  - Kotlin-specific FCIS implementation

- [TypeScript Guidelines](typescript-guidelines.md)
  - Type-safe functional patterns
  - Discriminated unions and exhaustive checking
  - Frontend/backend TypeScript conventions

- [Elixir Guidelines](elixir-guidelines.md)
  - OTP design principles with FCIS
  - GenServer patterns in the imperative shell
  - Pattern matching best practices

## Domain Modeling

- [Data Modeling Principles](data-modeling.md)
  - Sum types and product types
  - State machine modeling
  - Domain-driven design with functional programming

## Testing & Quality

- [Testing Strategy](testing-strategy.md)
  - Property-based testing for functional core
  - Integration testing for imperative shell
  - Test data generation patterns

## Project Templates

- [Project Structure](project-structure.md)
  - Standard directory layouts
  - Module boundaries and dependencies
  - Build configuration templates

## Code Style

- [Formatting and Naming](code-style.md)
  - Consistent naming conventions
  - Formatting rules per language
  - Documentation standards

## Performance & Infrastructure

- [API Design Patterns](api-design.md)
  - RESTful and GraphQL API patterns
  - Request/response transformations
  - Versioning strategies

- [Database Patterns](database-patterns.md)
  - Repository pattern implementation
  - Transaction management
  - Migration strategies
  - Query optimization

- [Performance Patterns](performance-patterns.md)
  - Memoization and caching strategies
  - Lazy evaluation techniques
  - Concurrency patterns
  - Monitoring and profiling

- [Security Patterns](security-patterns.md)
  - Input validation and sanitization
  - Authentication and authorization
  - Cryptography best practices
  - Privacy and compliance

---

**Important**: When starting any new project or feature, Claude must:
1. Read all relevant linked documents
2. Apply FCIS architecture as the default pattern
3. Use language-specific guidelines for implementation details
4. Ensure data models make invalid states unrepresentable