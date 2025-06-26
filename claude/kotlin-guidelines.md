# Kotlin Guidelines

## Core Principles

All Kotlin code must adhere to the [Functional Core, Imperative Shell](./fcis-architecture.md) architecture. This document provides Kotlin-specific implementation details.

## Data Modeling

### Sealed Classes for Sum Types

Always use sealed classes to model finite state spaces:

```kotlin
sealed class NetworkResult<out T> {
    data class Success<T>(val data: T) : NetworkResult<T>()
    data class Error(val exception: Exception) : NetworkResult<Nothing>()
    object Loading : NetworkResult<Nothing>()
}
```

### Data Classes for Product Types

Use data classes for immutable value objects:

```kotlin
data class User(
    val id: UserId,
    val email: Email,
    val profile: UserProfile
) {
    // Computed properties are fine in data classes
    val displayName: String get() = profile.preferredName ?: email.localPart
}
```

### Value Classes for Type Safety

Wrap primitive types to prevent mixing incompatible values:

```kotlin
@JvmInline
value class UserId(val value: UUID)

@JvmInline
value class Email(val value: String) {
    init {
        require(value.contains("@")) { "Invalid email format" }
    }
}
```

## Functional Core Patterns

### Arrow-kt Integration

When using Arrow-kt, prefer these patterns:

```kotlin
import arrow.core.*

// Use Either for operations that can fail
fun parseUser(input: String): Either<ParseError, User> =
    either {
        val id = parseUUID(input.substringBefore(",")).bind()
        val email = parseEmail(input.substringAfter(",")).bind()
        User(id, email)
    }

// Use Option for nullable operations
fun findUserById(id: UserId): Option<User> =
    repository.find(id).toOption()
```

### Extension Functions for Pipelines

Create extension functions for readable transformation pipelines:

```kotlin
fun OrderRequest.validate(): ValidatedNel<OrderError, ValidatedOrder> =
    validateNel(::validateItems, ::validateShipping, ::validatePayment) { items, shipping, payment ->
        ValidatedOrder(items, shipping, payment)
    }

// Chain operations fluently
fun processOrder(request: OrderRequest): Either<OrderError, Order> =
    request
        .validate()
        .toEither()
        .map { it.calculateTotals() }
        .map { it.applyDiscounts() }
        .map { it.finalize() }
```

## Imperative Shell Patterns

### Coroutines in the Shell Only

Keep coroutines at the boundary, pure functions in the core:

```kotlin
// Shell - handles async I/O
class UserService(
    private val repository: UserRepository,
    private val emailService: EmailService
) {
    suspend fun createUser(request: CreateUserRequest): Either<UserError, User> =
        either {
            // Imperative: Check uniqueness
            val exists = repository.existsByEmail(request.email)
            ensure(!exists) { UserError.EmailAlreadyExists }
            
            // Functional: Create user
            val user = UserCore.createUser(request).bind()
            
            // Imperative: Save and notify
            repository.save(user)
            emailService.sendWelcome(user.email)
            
            user
        }
}

// Core - pure functions only
object UserCore {
    fun createUser(request: CreateUserRequest): Either<ValidationError, User> =
        request.validate().map { validated ->
            User(
                id = UserId(UUID.randomUUID()),
                email = validated.email,
                profile = UserProfile.default()
            )
        }
}
```

### Structured Concurrency

Use structured concurrency for parallel operations:

```kotlin
suspend fun enrichUser(userId: UserId): EnrichedUser = coroutineScope {
    val user = async { userRepository.find(userId) }
    val orders = async { orderRepository.findByUser(userId) }
    val preferences = async { preferenceRepository.find(userId) }
    
    // Combine results in pure function
    UserCore.enrich(
        user.await(),
        orders.await(),
        preferences.await()
    )
}
```

## Error Handling

### Domain-Specific Error Types

Define errors as part of your domain model:

```kotlin
sealed class PaymentError {
    data class InsufficientFunds(val available: Money, val required: Money) : PaymentError()
    data class InvalidCard(val reason: String) : PaymentError()
    object CardExpired : PaymentError()
    data class NetworkError(val cause: Exception) : PaymentError()
}
```

### Railway-Oriented Programming

Chain operations that can fail:

```kotlin
fun processPayment(request: PaymentRequest): Either<PaymentError, PaymentReceipt> =
    either {
        val card = validateCard(request.card).bind()
        val amount = validateAmount(request.amount).bind()
        val authorization = authorize(card, amount).bind()
        val charge = captureCharge(authorization).bind()
        generateReceipt(charge)
    }
```

## Testing

### Property-Based Testing with Kotest

```kotlin
class UserSpec : StringSpec({
    "user email validation" {
        checkAll(Arb.string()) { input ->
            val result = Email.validate(input)
            when {
                input.contains("@") && input.length > 3 -> result.isRight()
                else -> result.isLeft()
            }
        }
    }
    
    "state transitions are valid" {
        checkAll(orderStateArb(), orderEventArb()) { state, event ->
            val result = transition(state, event)
            result.fold(
                { error -> error is InvalidTransition },
                { newState -> isValidTransition(state, event, newState) }
            )
        }
    }
})
```

### Test Data Builders

Create builders for complex test data:

```kotlin
fun aUser(
    id: UserId = UserId(UUID.randomUUID()),
    email: Email = Email("test@example.com"),
    profile: UserProfile = aUserProfile()
) = User(id, email, profile)

fun aUserProfile(
    preferredName: String? = null,
    timezone: TimeZone = TimeZone.UTC
) = UserProfile(preferredName, timezone)
```

## Performance Considerations

### Inline Functions

Use inline functions for higher-order functions in hot paths:

```kotlin
inline fun <T, R> List<T>.mapIf(
    predicate: (T) -> Boolean,
    transform: (T) -> R
): List<R> = mapNotNull { if (predicate(it)) transform(it) else null }
```

### Sequences for Large Data

Use sequences for lazy evaluation of large datasets:

```kotlin
fun processLargeDataset(items: Sequence<RawData>): Sequence<ProcessedData> =
    items
        .filter { it.isValid() }
        .map { it.normalize() }
        .map { ProcessedData.from(it) }
        .filter { it.meetsThreshold() }
```

## Code Style

### Naming Conventions

- Use `PascalCase` for types and classes
- Use `camelCase` for functions and properties
- Use `SCREAMING_SNAKE_CASE` for constants
- Prefix interfaces with `I` only for Java interop

### Function Organization

Order functions in classes/objects:
1. Factory methods
2. Primary operations
3. Supporting operations
4. Private helpers

### Explicit Return Types

Always specify return types for public functions:

```kotlin
// Good
fun calculateTotal(items: List<OrderItem>): Money = 
    items.sumOf { it.price * it.quantity }

// Avoid
fun calculateTotal(items: List<OrderItem>) = 
    items.sumOf { it.price * it.quantity }
```

## Interop Considerations

### Java Interop

When designing APIs for Java consumption:

```kotlin
@JvmOverloads
fun createUser(
    email: String,
    profile: UserProfile = UserProfile.default()
): User = User(UserId.generate(), Email(email), profile)

// Provide static methods
companion object {
    @JvmStatic
    fun fromJson(json: String): User = Json.decodeFromString(json)
}
```