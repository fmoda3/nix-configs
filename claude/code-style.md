# Code Style Guidelines

## General Principles

1. **Clarity over cleverness**: Write code that is easy to understand
2. **Consistency within a codebase**: Follow existing patterns
3. **Explicit over implicit**: Make intentions clear
4. **Pure functions first**: Default to immutability and no side effects

## Naming Conventions

### Kotlin

```kotlin
// Types: PascalCase
class User
interface PaymentProcessor
sealed class OrderState
data class EmailAddress

// Functions and properties: camelCase
fun calculateTotal(items: List<OrderItem>): Money
val userEmail: EmailAddress
var mutableState: State // Use var sparingly

// Constants: SCREAMING_SNAKE_CASE
const val MAX_RETRY_ATTEMPTS = 3
const val DEFAULT_TIMEOUT_MS = 5000

// Packages: lowercase
package com.example.core.models
package com.example.shell.services

// Type parameters: single letter or descriptive PascalCase
class Result<T, E>
class Cache<Key, Value>

// Boolean functions: prefix with is/has/can
fun isValid(): Boolean
fun hasPermission(user: User): Boolean
fun canProcess(order: Order): Boolean
```

### TypeScript

```typescript
// Types and interfaces: PascalCase
type User = { ... }
interface PaymentProcessor { ... }
type OrderState = "pending" | "completed"

// Functions and variables: camelCase
function calculateTotal(items: OrderItem[]): Money
const userEmail: EmailAddress
let mutableState: State // Use let sparingly

// Constants: SCREAMING_SNAKE_CASE
const MAX_RETRY_ATTEMPTS = 3
const DEFAULT_TIMEOUT_MS = 5000

// Enums: PascalCase with PascalCase values (avoid enums though)
enum Status {
    Active,
    Inactive
}

// File names: kebab-case
// user-service.ts
// order-calculator.ts
// payment-processor.test.ts

// React components: PascalCase
const UserProfile: React.FC<Props> = () => { ... }

// Hooks: camelCase with 'use' prefix
function useUserData() { ... }
```

### Elixir

```elixir
# Modules: PascalCase
defmodule Core.User do
defmodule Shell.PaymentService do

# Functions: snake_case
def calculate_total(items), do: ...
def is_valid?(user), do: ...

# Variables: snake_case
user_email = "test@example.com"
order_items = []

# Atoms: snake_case
:ok
:error
:invalid_state

# Constants: @snake_case
@max_retry_attempts 3
@default_timeout_ms 5000

# Boolean functions: suffix with ?
def valid?(user), do: ...
def has_permission?(user, resource), do: ...

# Dangerous functions: suffix with !
def save!(user), do: ...  # Raises on error
```

## Function Organization

### Function Length and Complexity

```kotlin
// Good: Small, focused functions
fun calculateSubtotal(items: List<OrderItem>): Money =
    items.sumOf { it.price * it.quantity }

fun applyDiscount(subtotal: Money, discount: Discount): Money =
    when (discount) {
        is PercentageDiscount -> subtotal * (1 - discount.percentage / 100)
        is FixedDiscount -> subtotal - discount.amount
        is NoDiscount -> subtotal
    }

fun calculateTax(amount: Money, taxRate: TaxRate): Money =
    amount * taxRate.value

fun calculateTotal(order: Order): Money {
    val subtotal = calculateSubtotal(order.items)
    val discounted = applyDiscount(subtotal, order.discount)
    val tax = calculateTax(discounted, order.taxRate)
    return discounted + tax
}

// Bad: Large, complex function doing everything
fun processOrder(order: Order): Money {
    // 100+ lines doing subtotal, discount, tax, validation, etc.
}
```

### Parameter Order

```typescript
// 1. Required parameters first
// 2. Optional parameters last
// 3. Config/options objects last
// 4. Callbacks last

// Good
function createUser(
    email: string,
    name: string,
    role?: UserRole,
    options?: CreateUserOptions
): Result<User, ValidationError>

// For functional style, data parameter first
function map<T, U>(items: T[], fn: (item: T) => U): U[]
function filter<T>(items: T[], predicate: (item: T) => boolean): T[]

// For curried functions, config first
const multiply = (factor: number) => (value: number) => value * factor
const double = multiply(2)
```

## Code Documentation

### Kotlin Documentation

```kotlin
/**
 * Processes a payment for the given order.
 * 
 * This function validates the payment method, checks available funds,
 * and attempts to capture the payment. If successful, it returns a
 * receipt. If unsuccessful, it returns a specific error.
 * 
 * @param order The order to process payment for
 * @param paymentMethod The customer's payment method
 * @return Success with receipt or Failure with payment error
 * 
 * @sample
 * ```
 * val result = processPayment(order, creditCard)
 * when (result) {
 *     is Success -> println("Payment successful: ${result.value.id}")
 *     is Failure -> println("Payment failed: ${result.error}")
 * }
 * ```
 */
fun processPayment(
    order: Order,
    paymentMethod: PaymentMethod
): Result<PaymentReceipt, PaymentError> {
    // Implementation
}
```

### TypeScript Documentation

```typescript
/**
 * Processes a payment for the given order.
 * 
 * @param order - The order to process payment for
 * @param paymentMethod - The customer's payment method  
 * @returns A Result containing either a receipt or payment error
 * 
 * @example
 * ```typescript
 * const result = await processPayment(order, creditCard)
 * if (result.kind === 'ok') {
 *   console.log(`Payment successful: ${result.value.id}`)
 * } else {
 *   console.log(`Payment failed: ${result.error}`)
 * }
 * ```
 */
export async function processPayment(
    order: Order,
    paymentMethod: PaymentMethod
): Promise<Result<PaymentReceipt, PaymentError>> {
    // Implementation
}

// For type definitions
/**
 * Represents a monetary amount with currency.
 * All amounts are stored in the smallest currency unit (e.g., cents).
 */
export interface Money {
    /** Amount in smallest currency unit */
    readonly amount: number
    /** ISO 4217 currency code */
    readonly currency: CurrencyCode
}
```

### Elixir Documentation

```elixir
@doc """
Processes a payment for the given order.

Returns `{:ok, receipt}` if successful, or `{:error, reason}` if failed.

## Parameters

  * `order` - The order to process payment for
  * `payment_method` - The customer's payment method

## Examples

    iex> processPayment(order, credit_card)
    {:ok, %Receipt{id: "rec_123", amount: 1000}}
    
    iex> processPayment(order, invalid_card)
    {:error, :card_declined}

"""
@spec process_payment(Order.t(), PaymentMethod.t()) :: 
  {:ok, Receipt.t()} | {:error, payment_error()}
def process_payment(order, payment_method) do
  # Implementation
end
```

## Formatting Rules

### Kotlin Formatting

```kotlin
// Indent with 4 spaces
class User(
    val id: UserId,
    val email: Email,
    val profile: Profile
) {
    fun updateProfile(updates: ProfileUpdate): User {
        return copy(
            profile = profile.merge(updates),
            updatedAt = Clock.now()
        )
    }
}

// Line breaks for readability
fun complexCalculation(
    firstParameter: Type1,
    secondParameter: Type2,
    thirdParameter: Type3
): Result<Output, Error> {
    return firstStep(firstParameter)
        .flatMap { secondStep(it, secondParameter) }
        .flatMap { thirdStep(it, thirdParameter) }
        .mapError { DomainError.from(it) }
}

// Trailing commas for easy addition
val config = Config(
    host = "localhost",
    port = 5432,
    database = "myapp",
    poolSize = 10,  // Trailing comma
)
```

### TypeScript Formatting

```typescript
// Indent with 2 spaces
export interface User {
  readonly id: UserId
  readonly email: Email  
  readonly profile: Profile
}

// Consistent semicolons (prefer none)
const calculateTotal = (items: Item[]): Money => {
  const subtotal = items.reduce((sum, item) => sum + item.price, 0)
  const tax = subtotal * 0.08
  return subtotal + tax
}

// Object and array formatting
const config = {
  api: {
    baseUrl: "https://api.example.com",
    timeout: 5000,
    retries: 3,
  },
  features: {
    enableNewUI: true,
    enableBetaFeatures: false,
  },
} as const

// Multiline function parameters
export function createOrder(
  customerId: CustomerId,
  items: OrderItem[],
  shippingAddress: Address,
  options?: CreateOrderOptions,
): Result<Order, OrderError> {
  // Implementation
}
```

### Elixir Formatting

```elixir
# Use mix format defaults
defmodule Core.Order do
  @enforce_keys [:id, :customer_id, :items]
  defstruct [
    :id,
    :customer_id,
    :items,
    :discount,
    :status,
    created_at: DateTime.utc_now()
  ]

  def new(attrs) do
    %__MODULE__{
      id: UUID.uuid4(),
      customer_id: attrs.customer_id,
      items: attrs.items,
      status: :draft
    }
  end

  # Pipeline formatting
  def process(order) do
    order
    |> validate()
    |> calculate_totals()
    |> apply_discounts()
    |> finalize()
  end

  # Pattern matching alignment
  def transition(order, event) do
    case {order.status, event} do
      {:draft, :submit}       -> {:ok, %{order | status: :submitted}}
      {:submitted, :approve}  -> {:ok, %{order | status: :approved}}
      {:approved, :ship}      -> {:ok, %{order | status: :shipped}}
      {_status, _event}       -> {:error, :invalid_transition}
    end
  end
end
```

## Import Organization

### Kotlin Imports

```kotlin
// Group imports by origin
import java.time.Instant
import java.util.UUID

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

import arrow.core.Either
import arrow.core.flatMap

import com.example.core.models.User
import com.example.core.logic.UserValidator
import com.example.shared.types.Result

// Avoid wildcard imports except for common utilities
import com.example.shared.extensions.*
```

### TypeScript Imports

```typescript
// External dependencies first
import { z } from 'zod'
import express from 'express'

// Absolute imports (from project root)
import { User, Order } from '@/core/models'
import { calculateTotal } from '@/core/logic/order-calculator'
import { Result } from '@/shared/types'

// Relative imports last
import { validateRequest } from './middleware'
import { formatResponse } from './utils'

// Type imports separated
import type { Request, Response } from 'express'
import type { ValidationError } from '@/core/errors'
```

### Elixir Aliases

```elixir
defmodule Shell.OrderService do
  # Group aliases by namespace
  alias Core.{Order, OrderValidator, OrderCalculator}
  alias Shell.{Repo, OrderRepo, EmailService}
  alias MyAppWeb.ErrorHelpers
  
  import Ecto.Query, only: [from: 2, where: 3]
  
  require Logger
  
  # Module implementation
end
```

## Error Handling Style

### Explicit Error Types

```kotlin
// Good: Explicit error types
sealed class PaymentError {
    data class InsufficientFunds(val available: Money, val required: Money) : PaymentError()
    data class CardDeclined(val reason: String) : PaymentError()
    object NetworkError : PaymentError()
}

// Bad: Generic exceptions
throw Exception("Payment failed")
```

### Consistent Error Patterns

```typescript
// Always use Result type for fallible operations
function parseEmail(input: string): Result<Email, ValidationError> {
  if (!input.includes('@')) {
    return err({ field: 'email', code: 'invalid_format' })
  }
  return ok(input as Email)
}

// Never throw in the functional core
// Bad
function divide(a: number, b: number): number {
  if (b === 0) throw new Error("Division by zero")
  return a / b
}

// Good
function divide(a: number, b: number): Result<number, MathError> {
  if (b === 0) return err({ kind: 'DivisionByZero' })
  return ok(a / b)
}
```

## Comments and Code Clarity

```kotlin
// Good: Explain why, not what
// We need to check inventory before payment to avoid 
// charging customers for out-of-stock items
val inventoryResult = checkInventory(order.items)

// Bad: Redundant comment
// Check if user is valid
if (user.isValid()) {
```

```typescript
// Good: Complex business logic explanation
// Apply discounts in order of precedence:
// 1. Item-level discounts
// 2. Category discounts  
// 3. Order-level discounts
// This ensures customers get the best possible price
const finalPrice = applyDiscountChain(order, discounts)

// Good: Document edge cases
// Returns empty array instead of null to avoid null checks downstream
function getActiveUsers(): User[] {
  return users.filter(u => u.status === 'active') ?? []
}
```

## Code Review Checklist

- [ ] Functions are small and focused
- [ ] Names clearly express intent
- [ ] No magic numbers or strings
- [ ] Errors are handled explicitly
- [ ] Tests cover edge cases
- [ ] Documentation explains why, not what
- [ ] Imports are organized and minimal
- [ ] No commented-out code
- [ ] Consistent formatting throughout
- [ ] Pure functions have no side effects