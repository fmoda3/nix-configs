# Data Modeling Principles

## Core Philosophy

Design data models that make invalid states impossible to represent. Every possible value of your types should represent a valid, meaningful state in your domain.

## Making Invalid States Unrepresentable

### Use Sum Types for Mutually Exclusive States

**Bad**: Using booleans and nullable fields
```kotlin
data class Payment(
    val isPending: Boolean,
    val isProcessing: Boolean,
    val isCompleted: Boolean,
    val transactionId: String?,  // Only set when processing/completed
    val receipt: Receipt?,       // Only set when completed
    val error: Error?           // Only set when failed
)
// Can represent invalid states like isPending=true AND isCompleted=true
```

**Good**: Using sealed classes/discriminated unions
```kotlin
sealed class Payment {
    object Pending : Payment()
    data class Processing(val transactionId: TransactionId) : Payment()
    data class Completed(val transactionId: TransactionId, val receipt: Receipt) : Payment()
    data class Failed(val error: PaymentError) : Payment()
}
// Every value is valid, impossible to have conflicting states
```

### Replace Primitive Obsession with Domain Types

**Bad**: Using primitives everywhere
```typescript
function transferMoney(
    fromAccount: string,
    toAccount: string,
    amount: number,
    currency: string
) { /* ... */ }

// Easy to mix up parameters
transferMoney(toId, fromId, 100, "USD") // Oops, swapped accounts!
```

**Good**: Create specific types
```typescript
type AccountId = string & { readonly _brand: "AccountId" }
type Money = { amount: Decimal; currency: Currency }

function transferMoney(
    from: AccountId,
    to: AccountId,
    amount: Money
) { /* ... */ }
// Type system prevents mixing up parameters
```

### Use Product Types for Data That Belongs Together

**Bad**: Separate related fields
```elixir
defstruct [
  :street_address,
  :city,
  :state,
  :postal_code,
  :country,
  :latitude,   # What if these don't match the address?
  :longitude
]
```

**Good**: Group cohesive data
```elixir
defmodule Address do
  defstruct [:street, :city, :state, :postal_code, :country]
end

defmodule Location do
  defstruct [:latitude, :longitude]
end

defmodule Place do
  defstruct [:address, :location]
  
  @type t :: %__MODULE__{
    address: Address.t(),
    location: Location.t() | nil
  }
end
```

## State Machine Modeling

### Explicit State Transitions

Model your domain as state machines where possible:

```kotlin
sealed class OrderState {
    object Draft : OrderState()
    data class Submitted(val submittedAt: Instant) : OrderState()
    data class Paid(val submittedAt: Instant, val paidAt: Instant) : OrderState()
    data class Shipped(
        val submittedAt: Instant,
        val paidAt: Instant,
        val shippedAt: Instant,
        val trackingNumber: TrackingNumber
    ) : OrderState()
    data class Delivered(
        val submittedAt: Instant,
        val paidAt: Instant,
        val shippedAt: Instant,
        val deliveredAt: Instant,
        val trackingNumber: TrackingNumber
    ) : OrderState()
    data class Cancelled(val cancelledAt: Instant, val reason: CancellationReason) : OrderState()
}

// State transitions become explicit functions
fun OrderState.submit(now: Instant): Result<OrderState> = when (this) {
    is Draft -> Ok(Submitted(now))
    else -> Err(InvalidTransition("Cannot submit order in state: $this"))
}
```

### Accumulating State Data

Notice how each state includes all data from previous states. This ensures you always have access to historical information without nullable fields.

## Validation at the Type Level

### Parse, Don't Validate

**Bad**: Validate repeatedly
```typescript
function processEmail(email: string) {
    if (!isValidEmail(email)) throw new Error("Invalid email")
    // ... later in the code ...
    if (!isValidEmail(email)) throw new Error("Invalid email") // Validating again!
    sendEmail(email)
}
```

**Good**: Parse into a validated type
```typescript
class Email {
    private constructor(private readonly value: string) {}
    
    static parse(input: string): Result<Email, ValidationError> {
        if (!isValidEmail(input)) {
            return err({ field: "email", message: "Invalid format" })
        }
        return ok(new Email(input))
    }
    
    toString(): string { return this.value }
}

function processEmail(email: Email) {
    // No validation needed - type guarantees validity
    sendEmail(email.toString())
}
```

### Smart Constructors

Use factory functions that ensure invariants:

```elixir
defmodule DateRange do
  @enforce_keys [:start_date, :end_date]
  defstruct [:start_date, :end_date]
  
  @type t :: %__MODULE__{
    start_date: Date.t(),
    end_date: Date.t()
  }
  
  # Smart constructor ensures start <= end
  def new(start_date, end_date) do
    if Date.compare(start_date, end_date) == :gt do
      {:error, "Start date must be before or equal to end date"}
    else
      {:ok, %__MODULE__{start_date: start_date, end_date: end_date}}
    end
  end
  
  # Convenience functions that maintain invariants
  def extend(range, days) do
    new_end = Date.add(range.end_date, days)
    {:ok, %{range | end_date: new_end}}
  end
end
```

## Modeling Optional Relationships

### Avoid Nullable References for Business Logic

**Bad**: Using null to represent absence
```kotlin
data class User(
    val id: UserId,
    val email: Email,
    val phoneNumber: String?,  // null if not verified
    val verifiedAt: Instant?   // null if not verified
)
```

**Good**: Model the states explicitly
```kotlin
sealed class PhoneNumber {
    object NotProvided : PhoneNumber()
    data class Unverified(val number: String) : PhoneNumber()
    data class Verified(val number: String, val verifiedAt: Instant) : PhoneNumber()
}

data class User(
    val id: UserId,
    val email: Email,
    val phoneNumber: PhoneNumber
)
```

## Modeling Collections

### Non-Empty Lists

When business logic requires at least one element:

```typescript
type NonEmptyArray<T> = [T, ...T[]]

interface Order {
    id: OrderId
    items: NonEmptyArray<OrderItem>  // Can't create order without items
    customer: Customer
}

// Helper functions
function nonEmptyArray<T>(head: T, ...tail: T[]): NonEmptyArray<T> {
    return [head, ...tail]
}

function addItem<T>(arr: NonEmptyArray<T>, item: T): NonEmptyArray<T> {
    return [...arr, item] as NonEmptyArray<T>
}
```

### Modeling Unique Collections

```elixir
defmodule UniqueList do
  @opaque t(element) :: %__MODULE__{
    items: [element],
    seen: MapSet.t(element)
  }
  
  defstruct items: [], seen: MapSet.new()
  
  def new(items \\ []) do
    Enum.reduce(items, %__MODULE__{}, &add(&2, &1))
  end
  
  def add(%__MODULE__{} = list, item) do
    if MapSet.member?(list.seen, item) do
      list
    else
      %{list | 
        items: list.items ++ [item],
        seen: MapSet.put(list.seen, item)
      }
    end
  end
  
  def to_list(%__MODULE__{items: items}), do: items
end
```

## Temporal Modeling

### Explicit Time Boundaries

```kotlin
sealed class Subscription {
    data class Trial(
        val startDate: LocalDate,
        val endDate: LocalDate
    ) : Subscription()
    
    data class Active(
        val startDate: LocalDate,
        val billingCycle: BillingCycle,
        val nextBillingDate: LocalDate
    ) : Subscription()
    
    data class Paused(
        val pausedAt: Instant,
        val resumeAt: Instant?
    ) : Subscription()
    
    data class Cancelled(
        val cancelledAt: Instant,
        val effectiveUntil: LocalDate
    ) : Subscription()
}
```

### Version History

Model changes over time explicitly:

```typescript
interface Versioned<T> {
    current: T
    history: Array<{
        value: T
        validFrom: Date
        validTo: Date
        changedBy: UserId
    }>
}

type Price = Versioned<Money>
type ProductDetails = Versioned<{
    name: string
    description: string
    category: Category
}>
```

## Error Modeling

### Rich Error Types

Don't use strings for errors - model them as types:

```elixir
defmodule Core.Errors do
  defmodule ValidationError do
    @type t :: %__MODULE__{
      field: atom(),
      code: error_code(),
      message: String.t(),
      metadata: map()
    }
    
    @type error_code :: 
      :required |
      :invalid_format |
      :out_of_range |
      :duplicate |
      :forbidden
      
    defstruct [:field, :code, :message, metadata: %{}]
  end
  
  defmodule DomainError do
    @type t :: 
      {:insufficient_inventory, product_id :: String.t(), available :: integer(), requested :: integer()} |
      {:payment_failed, reason :: payment_error()} |
      {:shipping_unavailable, address :: Address.t()} |
      {:discount_expired, code :: String.t(), expired_at :: DateTime.t()}
  end
end
```

## Modeling Workflows

### Pipeline Results

Model multi-step processes with accumulating results:

```typescript
type PipelineResult<T, E> = {
    value: T
    warnings: Warning[]
    metadata: Record<string, unknown>
}

type ValidationPipeline<T> = {
    validate: (input: unknown) => Result<T, ValidationError[]>
    transform: (value: T) => PipelineResult<T, TransformError>
    enrich: (result: PipelineResult<T, never>) => Promise<PipelineResult<T, EnrichmentError>>
}
```

## Anti-Patterns to Avoid

### 1. Stringly-Typed Domain

```kotlin
// Bad
data class Order(val status: String) // "pending", "processing", etc.

// Good  
sealed class OrderStatus { /* ... */ }
data class Order(val status: OrderStatus)
```

### 2. Boolean Blindness

```typescript
// Bad
function createUser(email: string, isAdmin: boolean, isActive: boolean, isVerified: boolean)

// Good
type UserRole = "customer" | "admin" | "support"
type UserStatus = "pending_verification" | "active" | "suspended"
function createUser(email: Email, role: UserRole, status: UserStatus)
```

### 3. Primitive Validation Scattering

```elixir
# Bad - validation logic spread everywhere
def process_phone(phone) do
  if valid_phone?(phone) do
    # ... more validation later
    if valid_phone?(phone) do  # Validating again!
      # ...
    end
  end
end

# Good - parse once, use everywhere
def process_phone(phone_string) do
  with {:ok, phone} <- PhoneNumber.parse(phone_string) do
    # phone is guaranteed valid
    do_something(phone)
  end
end
```

## Design Checklist

When modeling a domain concept, ask:

1. **Can this type represent an invalid state?** If yes, redesign.
2. **Am I using primitives where a domain type would be clearer?**
3. **Are related fields grouped together?**
4. **Are mutually exclusive states modeled as sum types?**
5. **Do my functions return rich types instead of booleans/nulls?**
6. **Are all possible states explicitly modeled?**
7. **Can invalid state transitions occur?**
8. **Are temporal aspects explicitly modeled?**
9. **Do my error types convey meaningful information?**
10. **Is validation happening at type construction?**