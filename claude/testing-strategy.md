# Testing Strategy

## Core Philosophy

Testing in a Functional Core, Imperative Shell architecture focuses on exhaustive testing of the pure functional core and integration testing of the imperative shell. The functional core's purity makes it trivial to test, while the shell requires careful orchestration testing.

## Testing Pyramid for FCIS

```
         ╱ E2E Tests ╲         <- Minimal, happy paths only
        ╱─────────────╲
       ╱ Integration  ╲       <- Shell coordination
      ╱───────────────╲
     ╱ Contract Tests  ╲     <- Shell/Core boundaries  
    ╱─────────────────╲
   ╱  Property Tests   ╲    <- Core invariants
  ╱───────────────────╲
 ╱    Unit Tests       ╲   <- Core logic (majority)
╱─────────────────────╲
```

## Functional Core Testing

### Unit Tests - Exhaustive Coverage

Test every edge case since pure functions are easy to test:

```kotlin
class PaymentCalculatorTest {
    @Test
    fun `calculates subtotal correctly`() {
        val items = listOf(
            OrderItem(ProductId("1"), quantity = 2, price = Money(10.00)),
            OrderItem(ProductId("2"), quantity = 1, price = Money(25.00))
        )
        
        val result = PaymentCalculator.calculateSubtotal(items)
        
        assertEquals(Money(45.00), result)
    }
    
    @Test
    fun `applies percentage discount`() {
        val subtotal = Money(100.00)
        val discount = PercentageDiscount(10)
        
        val result = PaymentCalculator.applyDiscount(subtotal, discount)
        
        assertEquals(Money(90.00), result)
    }
    
    @Test
    fun `handles empty item list`() {
        val result = PaymentCalculator.calculateSubtotal(emptyList())
        
        assertEquals(Money.ZERO, result)
    }
}
```

### Property-Based Testing

Verify invariants hold for all inputs:

```typescript
import { fc } from 'fast-check'

describe('OrderStateMachine', () => {
    it('should never transition to invalid state', () => {
        fc.assert(
            fc.property(
                orderStateArbitrary(),
                orderEventArbitrary(),
                (state, event) => {
                    const result = transition(state, event)
                    
                    // Property: all transitions result in valid states
                    if (result.kind === 'ok') {
                        expect(isValidState(result.value)).toBe(true)
                    }
                    
                    // Property: invalid transitions are explicitly rejected
                    if (result.kind === 'err') {
                        expect(result.error.kind).toBe('InvalidTransition')
                    }
                }
            )
        )
    })
    
    it('should maintain monotonic timestamps', () => {
        fc.assert(
            fc.property(
                fc.array(orderEventArbitrary(), { minLength: 1, maxLength: 10 }),
                (events) => {
                    const finalState = events.reduce(
                        (state, event) => applyEvent(state, event),
                        initialOrderState()
                    )
                    
                    const timestamps = extractTimestamps(finalState)
                    const sorted = [...timestamps].sort()
                    
                    // Property: timestamps are always in order
                    expect(timestamps).toEqual(sorted)
                }
            )
        )
    })
})
```

```elixir
defmodule Core.UserTest do
  use ExUnit.Case
  use ExUnitProperties
  
  property "email normalization is idempotent" do
    check all email <- valid_email_generator() do
      normalized_once = User.normalize_email(email)
      normalized_twice = User.normalize_email(normalized_once)
      
      assert normalized_once == normalized_twice
    end
  end
  
  property "age calculation is always non-negative" do
    check all birth_date <- past_date_generator(),
              current_date <- date_after(birth_date) do
      age = User.calculate_age(birth_date, current_date)
      
      assert age >= 0
      assert age <= 200  # Sanity check
    end
  end
end
```

### Parameterized Tests

Test multiple scenarios with the same logic:

```kotlin
@ParameterizedTest
@MethodSource("discountScenarios")
fun `calculates final price with various discounts`(
    scenario: DiscountScenario
) {
    val result = PriceCalculator.calculateFinalPrice(
        basePrice = scenario.basePrice,
        discounts = scenario.discounts,
        taxRate = scenario.taxRate
    )
    
    assertEquals(scenario.expectedPrice, result)
}

companion object {
    @JvmStatic
    fun discountScenarios() = listOf(
        DiscountScenario(
            basePrice = Money(100),
            discounts = listOf(PercentageDiscount(10)),
            taxRate = TaxRate(0.08),
            expectedPrice = Money(97.20) // (100 * 0.9) * 1.08
        ),
        DiscountScenario(
            basePrice = Money(100),
            discounts = listOf(FixedDiscount(Money(20)), PercentageDiscount(10)),
            taxRate = TaxRate(0.08),
            expectedPrice = Money(77.76) // ((100 - 20) * 0.9) * 1.08
        )
        // ... more scenarios
    )
}
```

## Imperative Shell Testing

### Integration Tests

Test the coordination between components:

```typescript
describe('UserService', () => {
    let userService: UserService
    let mockRepo: MockUserRepository
    let mockEmailService: MockEmailService
    
    beforeEach(() => {
        mockRepo = new MockUserRepository()
        mockEmailService = new MockEmailService()
        userService = new UserService(mockRepo, mockEmailService)
    })
    
    it('should create user and send welcome email', async () => {
        const request = { email: 'test@example.com', name: 'Test User' }
        
        const result = await userService.createUser(request)
        
        expect(result.kind).toBe('ok')
        expect(mockRepo.saved).toHaveLength(1)
        expect(mockEmailService.sentEmails).toHaveLength(1)
        expect(mockEmailService.sentEmails[0].template).toBe('welcome')
    })
    
    it('should rollback on email failure', async () => {
        mockEmailService.shouldFail = true
        const request = { email: 'test@example.com', name: 'Test User' }
        
        const result = await userService.createUser(request)
        
        expect(result.kind).toBe('err')
        expect(mockRepo.saved).toHaveLength(0)  // Rollback occurred
        expect(mockEmailService.sentEmails).toHaveLength(0)
    })
})