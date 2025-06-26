# API Design Patterns

## Core Principles

APIs are part of the imperative shell but should be designed to maximize use of the functional core. Every API endpoint should be a thin orchestration layer that delegates business logic to pure functions.

## RESTful API Design

### Resource Modeling

```typescript
// Good: Resources match domain models
GET    /api/orders              // List orders
GET    /api/orders/:id          // Get specific order
POST   /api/orders              // Create order
PUT    /api/orders/:id          // Update entire order
PATCH  /api/orders/:id          // Partial update
DELETE /api/orders/:id          // Delete order

// State transitions as sub-resources
POST   /api/orders/:id/submit   // Submit draft order
POST   /api/orders/:id/cancel   // Cancel order
POST   /api/orders/:id/ship     // Ship order

// Relationships as sub-resources
GET    /api/orders/:id/items    // Order items
POST   /api/orders/:id/items    // Add item to order
DELETE /api/orders/:id/items/:itemId
```

### Request/Response Types

```kotlin
// Define explicit API types separate from domain types
data class CreateOrderRequest(
    val customerId: String,
    val items: List<OrderItemRequest>,
    val shippingAddress: AddressRequest
)

data class OrderItemRequest(
    val productId: String,
    val quantity: Int
)

// Transform to domain types in the shell
fun CreateOrderRequest.toDomain(): Result<OrderCommand, ValidationError> {
    return OrderCommand.create(
        customerId = CustomerId(this.customerId),
        items = this.items.map { it.toDomain() },
        shippingAddress = this.shippingAddress.toDomain()
    )
}

// Response types with explicit fields
data class OrderResponse(
    val id: String,
    val status: String,
    val items: List<OrderItemResponse>,
    val totals: OrderTotalsResponse,
    val createdAt: String,
    val links: OrderLinks
)

data class OrderLinks(
    val self: String,
    val cancel: String?,
    val submit: String?
)
```

### Error Responses

```typescript
// Consistent error structure
interface ApiError {
  readonly code: string
  readonly message: string
  readonly details?: Record<string, unknown>
  readonly timestamp: string
  readonly traceId: string
}

interface ValidationApiError extends ApiError {
  readonly code: "VALIDATION_ERROR"
  readonly details: {
    readonly errors: Array<{
      readonly field: string
      readonly code: string
      readonly message: string
    }>
  }
}

// Transform domain errors to API errors
function toApiError(error: DomainError, traceId: string): ApiError {
  switch (error.kind) {
    case "ValidationError":
      return {
        code: "VALIDATION_ERROR",
        message: "Validation failed",
        details: {
          errors: error.errors.map(e => ({
            field: e.field,
            code: e.code,
            message: e.message
          }))
        },
        timestamp: new Date().toISOString(),
        traceId
      }
    
    case "BusinessError":
      return {
        code: error.code.toUpperCase(),
        message: error.message,
        details: error.context,
        timestamp: new Date().toISOString(),
        traceId
      }
  }
}
```

### HTTP Status Codes

```elixir
defmodule MyAppWeb.ApiHelpers do
  @doc """
  Maps domain results to appropriate HTTP responses
  """
  def render_result(conn, result) do
    case result do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> json(data)
      
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Resource not found"})
      
      {:error, %ValidationError{} = error} ->
        conn
        |> put_status(:bad_request)
        |> json(format_validation_error(error))
      
      {:error, %BusinessError{code: :insufficient_funds} = error} ->
        conn
        |> put_status(:payment_required)
        |> json(format_business_error(error))
      
      {:error, %BusinessError{} = error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(format_business_error(error))
      
      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Internal server error"})
    end
  end
end
```

## API Versioning

### URL Versioning Strategy

```typescript
// Version in URL for major versions
const routes = {
  v1: {
    orders: "/api/v1/orders",
    users: "/api/v1/users"
  },
  v2: {
    orders: "/api/v2/orders",
    users: "/api/v2/users"
  }
}

// Version-specific transformers
namespace ApiV1 {
  export function toOrderResponse(order: Order): OrderResponseV1 {
    return {
      id: order.id,
      status: order.status,
      // V1 specific fields
    }
  }
}

namespace ApiV2 {
  export function toOrderResponse(order: Order): OrderResponseV2 {
    return {
      id: order.id,
      status: mapStatusToV2(order.status),
      // V2 includes additional fields
      statusHistory: order.history.map(toStatusEvent)
    }
  }
}
```

### Backward Compatibility

```kotlin
// Support multiple versions via adapters
class OrderControllerV1(
    private val orderService: OrderService
) {
    @PostMapping("/api/v1/orders")
    fun createOrder(@RequestBody request: CreateOrderRequestV1): OrderResponseV1 {
        // Adapt V1 request to current domain model
        val command = request.toCurrentCommand()
        val result = orderService.createOrder(command)
        
        // Adapt current domain model to V1 response
        return result.map { it.toV1Response() }
            .getOrElse { throw it.toApiException() }
    }
}

// Deprecation headers
@GetMapping("/api/v1/users/{id}")
@Deprecated("Use /api/v2/users/{id}")
fun getUserV1(@PathVariable id: String): ResponseEntity<UserV1> {
    return ResponseEntity.ok()
        .header("Deprecation", "true")
        .header("Link", "</api/v2/users/$id>; rel=\"successor-version\"")
        .body(userService.getUser(id).toV1())
}
```

## GraphQL Patterns

### Schema Design

```graphql
# Domain types mapped to GraphQL
type Order {
  id: ID!
  status: OrderStatus!
  items: [OrderItem!]!
  totals: OrderTotals!
  customer: Customer!
  
  # Computed fields via functional core
  estimatedDelivery: DateTime
  availableActions: [OrderAction!]!
}

enum OrderStatus {
  DRAFT
  SUBMITTED
  PROCESSING
  SHIPPED
  DELIVERED
  CANCELLED
}

type OrderAction {
  action: String!
  available: Boolean!
  reason: String
}

# Mutations match domain commands
type Mutation {
  createOrder(input: CreateOrderInput!): CreateOrderPayload!
  submitOrder(id: ID!): SubmitOrderPayload!
  cancelOrder(id: ID!, reason: String!): CancelOrderPayload!
}

# Explicit error handling
type CreateOrderPayload {
  order: Order
  errors: [UserError!]
}

type UserError {
  field: String
  message: String!
  code: String!
}
```

### Resolver Implementation

```typescript
// Resolvers delegate to functional core
const resolvers = {
  Query: {
    order: async (_, { id }, context) => {
      const result = await context.orderService.getOrder(id)
      if (result.kind === 'err') {
        throw new GraphQLError(result.error.message, {
          extensions: { code: result.error.code }
        })
      }
      return result.value
    }
  },
  
  Order: {
    // Computed fields use pure functions
    estimatedDelivery: (order) => {
      return OrderCalculator.estimateDelivery(order)
    },
    
    availableActions: (order) => {
      return OrderStateMachine.availableActions(order.status)
        .map(action => ({
          action: action.type,
          available: true,
          reason: null
        }))
    }
  },
  
  Mutation: {
    createOrder: async (_, { input }, context) => {
      // Transform GraphQL input to domain command
      const command = transformCreateOrderInput(input)
      
      // Delegate to service
      const result = await context.orderService.createOrder(command)
      
      // Transform result to GraphQL response
      return {
        order: result.kind === 'ok' ? result.value : null,
        errors: result.kind === 'err' ? formatErrors(result.error) : []
      }
    }
  }
}
```

## Pagination Patterns

### Cursor-Based Pagination

```elixir
defmodule MyAppWeb.PaginationHelpers do
  @default_limit 20
  @max_limit 100
  
  defmodule Page do
    @type t :: %__MODULE__{
      items: [any()],
      cursor: String.t() | nil,
      has_more: boolean()
    }
    
    defstruct [:items, :cursor, :has_more]
  end
  
  def paginate(query, params) do
    limit = get_limit(params)
    cursor = get_cursor(params)
    
    # Fetch one extra to determine has_more
    items = query
    |> apply_cursor(cursor)
    |> limit(^(limit + 1))
    |> Repo.all()
    
    has_more = length(items) > limit
    items = Enum.take(items, limit)
    next_cursor = if has_more, do: encode_cursor(List.last(items)), else: nil
    
    %Page{
      items: items,
      cursor: next_cursor,
      has_more: has_more
    }
  end
  
  defp get_limit(params) do
    params
    |> Map.get("limit", @default_limit)
    |> min(@max_limit)
  end
  
  defp encode_cursor(item) do
    %{id: item.id, created_at: item.created_at}
    |> Jason.encode!()
    |> Base.url_encode64()
  end
end
```

### Response Format

```typescript
interface PaginatedResponse<T> {
  readonly data: readonly T[]
  readonly pagination: {
    readonly cursor?: string
    readonly hasMore: boolean
    readonly total?: number // Only if efficiently countable
  }
  readonly links: {
    readonly self: string
    readonly next?: string
  }
}

// Usage
app.get('/api/orders', async (req, res) => {
  const { cursor, limit = 20 } = req.query
  
  const page = await orderService.listOrders({
    cursor: cursor as string,
    limit: Math.min(Number(limit), 100)
  })
  
  const response: PaginatedResponse<OrderResponse> = {
    data: page.items.map(toOrderResponse),
    pagination: {
      cursor: page.nextCursor,
      hasMore: page.hasMore
    },
    links: {
      self: `/api/orders?limit=${limit}`,
      next: page.nextCursor 
        ? `/api/orders?cursor=${page.nextCursor}&limit=${limit}`
        : undefined
    }
  }
  
  res.json(response)
})
```

## API Authentication & Authorization

### Token Validation in Shell

```kotlin
// Authentication middleware
class AuthenticationFilter(
    private val tokenValidator: TokenValidator
) : Filter {
    override fun doFilter(
        request: ServletRequest,
        response: ServletResponse,
        chain: FilterChain
    ) {
        val httpRequest = request as HttpServletRequest
        val token = extractToken(httpRequest)
        
        if (token == null) {
            sendUnauthorized(response as HttpServletResponse)
            return
        }
        
        // Validate token and extract claims
        when (val result = tokenValidator.validate(token)) {
            is Success -> {
                // Add user context to request
                httpRequest.setAttribute("userId", result.value.userId)
                httpRequest.setAttribute("permissions", result.value.permissions)
                chain.doFilter(request, response)
            }
            is Failure -> {
                sendUnauthorized(response as HttpServletResponse)
            }
        }
    }
}

// Authorization in controllers
@RestController
class OrderController(
    private val orderService: OrderService,
    private val authz: AuthorizationService
) {
    @GetMapping("/api/orders/{id}")
    fun getOrder(
        @PathVariable id: String,
        @RequestAttribute userId: UserId,
        @RequestAttribute permissions: Set<Permission>
    ): OrderResponse {
        // Check authorization using functional core
        val order = orderService.getOrder(OrderId(id))
            .getOrElse { throw NotFoundException() }
        
        if (!authz.canViewOrder(userId, permissions, order)) {
            throw ForbiddenException()
        }
        
        return order.toResponse()
    }
}
```

## Rate Limiting

```typescript
// Rate limit configuration per endpoint
const rateLimits = {
  '/api/orders': {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100,
    keyGenerator: (req) => req.userId || req.ip
  },
  '/api/orders/*/submit': {
    windowMs: 60 * 1000, // 1 minute
    max: 5, // Max 5 order submissions per minute
    keyGenerator: (req) => req.userId
  }
}

// Rate limit headers
interface RateLimitHeaders {
  'X-RateLimit-Limit': string
  'X-RateLimit-Remaining': string
  'X-RateLimit-Reset': string
}

function addRateLimitHeaders(
  res: Response,
  limit: number,
  remaining: number,
  resetTime: Date
): void {
  res.set({
    'X-RateLimit-Limit': limit.toString(),
    'X-RateLimit-Remaining': Math.max(0, remaining).toString(),
    'X-RateLimit-Reset': resetTime.toISOString()
  })
}
```

## API Documentation

### OpenAPI/Swagger Annotations

```kotlin
@RestController
@Tag(name = "Orders", description = "Order management operations")
class OrderController {
    @Operation(
        summary = "Create a new order",
        description = "Creates a new order in draft status"
    )
    @ApiResponses(
        ApiResponse(
            responseCode = "201",
            description = "Order created successfully",
            content = [Content(schema = Schema(implementation = OrderResponse::class))]
        ),
        ApiResponse(
            responseCode = "400",
            description = "Invalid request",
            content = [Content(schema = Schema(implementation = ValidationErrorResponse::class))]
        )
    )
    @PostMapping("/api/orders")
    fun createOrder(
        @RequestBody 
        @Valid 
        @Schema(description = "Order creation request")
        request: CreateOrderRequest
    ): ResponseEntity<OrderResponse> {
        // Implementation
    }
}
```

### Self-Documenting Responses

```typescript
// Include helpful information in responses
interface ApiResponse<T> {
  readonly data: T
  readonly meta?: {
    readonly version: string
    readonly deprecation?: {
      readonly sunset: string
      readonly alternative: string
    }
  }
  readonly _links?: {
    readonly self: { href: string }
    readonly related?: Record<string, { href: string; title?: string }>
  }
}

// Example response
{
  "data": {
    "id": "ord_123",
    "status": "submitted",
    "total": { "amount": 10000, "currency": "USD" }
  },
  "meta": {
    "version": "2.0"
  },
  "_links": {
    "self": { "href": "/api/orders/ord_123" },
    "related": {
      "customer": { 
        "href": "/api/customers/cust_456",
        "title": "Order customer"
      },
      "invoice": {
        "href": "/api/invoices/inv_789",
        "title": "Order invoice"
      }
    }
  }
}
```

## API Testing Patterns

```elixir
defmodule MyAppWeb.OrderControllerTest do
  use MyAppWeb.ConnCase
  
  describe "POST /api/orders" do
    test "creates order with valid data", %{conn: conn} do
      request = %{
        customer_id: "cust_123",
        items: [
          %{product_id: "prod_456", quantity: 2}
        ]
      }
      
      conn = conn
      |> put_req_header("authorization", "Bearer #{valid_token()}")
      |> post("/api/orders", request)
      
      assert %{"id" => id, "status" => "draft"} = json_response(conn, 201)
      assert id =~ ~r/^ord_/
    end
    
    test "returns validation errors for invalid data", %{conn: conn} do
      request = %{customer_id: "", items: []}
      
      conn = conn
      |> put_req_header("authorization", "Bearer #{valid_token()}")
      |> post("/api/orders", request)
      
      assert %{
        "error" => "VALIDATION_ERROR",
        "details" => %{
          "errors" => errors
        }
      } = json_response(conn, 400)
      
      assert Enum.find(errors, &(&1["field"] == "customer_id"))
      assert Enum.find(errors, &(&1["field"] == "items"))
    end
  end
end
```

## Best Practices Checklist

- [ ] APIs are thin orchestration layers delegating to functional core
- [ ] Request/response types are separate from domain types
- [ ] Errors are consistently structured across all endpoints
- [ ] HTTP status codes accurately reflect the operation result
- [ ] Pagination is implemented consistently
- [ ] Authentication/authorization logic is in the functional core
- [ ] Rate limiting is applied appropriately
- [ ] API is versioned with clear migration paths
- [ ] All endpoints are documented with examples
- [ ] Integration tests cover happy paths and error cases