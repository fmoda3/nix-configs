# Claude Code Guidelines: Functional Core, Imperative Shell

## Core Philosophy

All code in this project follows the **Functional Core, Imperative Shell** (FCIS) architecture pattern. This means:

- **Functional Core**: Pure, immutable business logic with no side effects
- **Imperative Shell**: Thin layer handling I/O, state mutations, and external interactions

## Data Modeling Principles

### 1. Make Invalid States Unrepresentable

Design data models that can only express valid states. Use sum types (sealed classes/unions) to enumerate all possible states explicitly.

**Kotlin Example:**
```kotlin
sealed class PaymentState {
    object Pending : PaymentState()
    data class Processing(val transactionId: String) : PaymentState()
    data class Completed(val transactionId: String, val receipt: Receipt) : PaymentState()
    data class Failed(val error: PaymentError) : PaymentState()
}
```

**TypeScript Example:**
```typescript
type PaymentState = 
    | { kind: "pending" }
    | { kind: "processing"; transactionId: string }
    | { kind: "completed"; transactionId: string; receipt: Receipt }
    | { kind: "failed"; error: PaymentError }
```

### 2. Data First, Behavior Second

Always define your data models before implementing behavior. The shape of your data should guide the structure of your functions.

## Functional Core Guidelines

### Pure Functions Only

The functional core must contain only pure functions:
- No I/O operations (file system, network, database)
- No random number generation
- No date/time access
- No logging or console output
- No exceptions (use Result/Either types)

### Error Handling

Use explicit error types instead of exceptions:

**Kotlin:**
```kotlin
sealed class Result<out T, out E> {
    data class Success<T>(val value: T) : Result<T, Nothing>()
    data class Failure<E>(val error: E) : Result<Nothing, E>()
}
```

**TypeScript:**
```typescript
type Result<T, E> = 
    | { kind: "success"; value: T }
    | { kind: "failure"; error: E }
```

### Immutability

All data structures in the functional core must be immutable:
- Use `val` in Kotlin, never `var`
- Use `const` and `readonly` in TypeScript
- Return new instances instead of modifying existing ones

## Imperative Shell Guidelines

### Minimal Logic

The imperative shell should contain minimal business logic. Its responsibilities:
1. Gather inputs from external sources
2. Call functional core with inputs
3. Handle outputs/side effects based on core's results

### Dependency Injection

Pass all dependencies explicitly to the shell. The functional core should never directly access external resources.

**Kotlin Example:**
```kotlin
class PaymentShell(
    private val repository: PaymentRepository,
    private val emailService: EmailService,
    private val logger: Logger
) {
    suspend fun processPayment(request: PaymentRequest): PaymentResult {
        // Imperative: Fetch data
        val account = repository.getAccount(request.accountId)
        
        // Functional: Process business logic
        val result = PaymentCore.processPayment(account, request)
        
        // Imperative: Handle side effects
        when (result) {
            is Success -> {
                repository.save(result.payment)
                emailService.sendReceipt(result.receipt)
                logger.info("Payment processed: ${result.payment.id}")
            }
            is Failure -> {
                logger.error("Payment failed: ${result.error}")
            }
        }
        
        return result
    }
}
```

## Testing Strategy

### Functional Core Testing

- Test exhaustively with unit tests
- Use property-based testing where applicable
- No mocking required (pure functions)
- Test all edge cases and state transitions

### Imperative Shell Testing

- Use integration tests with real or in-memory implementations
- Mock external dependencies sparingly
- Focus on correct coordination between components

## Code Organization

### Directory Structure

```
src/
├── core/           # Functional core
│   ├── models/     # Data models and types
│   ├── logic/      # Pure business logic
│   └── validation/ # Pure validation functions
├── shell/          # Imperative shell
│   ├── api/        # HTTP handlers
│   ├── db/         # Database access
│   ├── services/   # External service integrations
│   └── config/     # Configuration loading
└── shared/         # Shared utilities (must be pure)
```

### Module Boundaries

- Core modules must not import from shell modules
- Shell modules can import from core modules
- Use dependency inversion for core to define interfaces that shell implements

## Language-Specific Guidelines

### Kotlin

- Prefer `data class` for models
- Use `sealed class` for sum types
- Leverage `copy()` for immutable updates
- Use coroutines in shell, pure functions in core

### TypeScript

- Use discriminated unions for sum types
- Prefer `type` over `interface` for data models
- Use `readonly` arrays and objects
- Leverage spread operator for immutable updates

### Elixir

- Pattern match extensively
- Use structs for data modeling
- Keep GenServers in the shell layer
- Pure functions should not send/receive messages

## Common Patterns

### State Machines

Model state transitions explicitly:

```kotlin
fun transition(state: OrderState, event: OrderEvent): Result<OrderState, OrderError> =
    when (state) {
        is OrderState.Draft -> when (event) {
            is OrderEvent.Submit -> validateOrder(state.items)
                .map { OrderState.Submitted(orderId = generateId(), items = state.items) }
            else -> Result.Failure(InvalidTransition(state, event))
        }
        // ... other states
    }
```

### Validation Pipelines

Chain validations functionally:

```typescript
const validateUser = (input: UserInput): Result<ValidatedUser, ValidationError[]> =>
    pipe(
        input,
        validateEmail,
        chain(validateAge),
        chain(validateUsername),
        map(createValidatedUser)
    )
```

## Anti-Patterns to Avoid

1. **Hidden State**: No global variables or singletons in core
2. **Implicit Dependencies**: All dependencies must be explicit parameters
3. **Mixed Concerns**: Don't mix I/O with business logic
4. **Partial Functions**: Avoid functions that can throw exceptions
5. **Stringly-Typed Code**: Use proper types instead of strings for domain concepts

## Decision Checklist

When implementing a feature, ask:

1. Is the business logic pure and testable without mocks?
2. Can invalid states be represented in the data model?
3. Are all possible states explicitly modeled?
4. Is the imperative shell as thin as possible?
5. Are errors handled explicitly without exceptions?
6. Is all data immutable within the functional core?

## References

- [Functional Core, Imperative Shell](https://www.destroyallsoftware.com/screencasts/catalog/functional-core-imperative-shell)
- [Making Impossible States Impossible](https://www.youtube.com/watch?v=IcgmSRJHu_8)
- [Parse, Don't Validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)