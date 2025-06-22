# Database Patterns

## Core Principles

The database layer belongs entirely in the imperative shell. The functional core should never know about database schemas, queries, or persistence concerns. Database operations should map between persistent schemas and domain models cleanly.

## Schema Design

### Domain Model vs Database Schema

```sql
-- Database schema optimized for storage and queries
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    email_normalized VARCHAR(255) NOT NULL,
    display_name VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version INTEGER NOT NULL DEFAULT 1,
    
    -- Indexes for common queries
    INDEX idx_users_email_normalized (email_normalized),
    INDEX idx_users_status_created (status, created_at DESC),
    
    -- Constraints matching domain rules
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
    CONSTRAINT chk_status CHECK (status IN ('active', 'suspended', 'deleted'))
);

-- Separate sensitive data
CREATE TABLE user_credentials (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    mfa_secret VARCHAR(255),
    last_login_at TIMESTAMPTZ,
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ
);
```

### Mapping to Domain Models

```kotlin
// Database entity
@Entity
@Table(name = "users")
data class UserEntity(
    @Id
    val id: UUID = UUID.randomUUID(),
    
    @Column(nullable = false, unique = true)
    val email: String,
    
    @Column(name = "email_normalized", nullable = false)
    val emailNormalized: String,
    
    @Column(name = "display_name")
    val displayName: String?,
    
    @Enumerated(EnumType.STRING)
    val status: UserStatusEntity = UserStatusEntity.ACTIVE,
    
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),
    
    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant = Instant.now(),
    
    @Version
    val version: Long = 1
)

enum class UserStatusEntity {
    ACTIVE, SUSPENDED, DELETED
}

// Mapper to domain model (in shell)
object UserMapper {
    fun toDomain(entity: UserEntity): User {
        return User(
            id = UserId(entity.id.toString()),
            email = Email(entity.email),
            profile = Profile(
                displayName = entity.displayName
            ),
            status = when (entity.status) {
                UserStatusEntity.ACTIVE -> UserStatus.Active
                UserStatusEntity.SUSPENDED -> UserStatus.Suspended(entity.updatedAt)
                UserStatusEntity.DELETED -> UserStatus.Deleted(entity.updatedAt)
            }
        )
    }
    
    fun toEntity(user: User): UserEntity {
        return UserEntity(
            id = UUID.fromString(user.id.value),
            email = user.email.value,
            emailNormalized = user.email.value.lowercase(),
            displayName = user.profile.displayName,
            status = when (user.status) {
                is UserStatus.Active -> UserStatusEntity.ACTIVE
                is UserStatus.Suspended -> UserStatusEntity.SUSPENDED
                is UserStatus.Deleted -> UserStatusEntity.DELETED
            }
        )
    }
}
```

## Repository Pattern

### Repository Interface

```typescript
// Define repository interface in the shell
export interface UserRepository {
  findById(id: UserId): Promise<Option<User>>
  findByEmail(email: Email): Promise<Option<User>>
  exists(id: UserId): Promise<boolean>
  save(user: User): Promise<void>
  delete(id: UserId): Promise<void>
  
  // Complex queries return domain types
  findActiveUsersByDomain(domain: string): Promise<User[]>
  findUsersCreatedBetween(start: Date, end: Date): Promise<User[]>
}

// Implementation using your ORM of choice
export class SqlUserRepository implements UserRepository {
  constructor(private db: Database) {}
  
  async findById(id: UserId): Promise<Option<User>> {
    const entity = await this.db.users.findUnique({
      where: { id: id.value }
    })
    
    return entity ? some(UserMapper.toDomain(entity)) : none
  }
  
  async save(user: User): Promise<void> {
    const entity = UserMapper.toEntity(user)
    
    await this.db.users.upsert({
      where: { id: entity.id },
      create: entity,
      update: {
        ...entity,
        updatedAt: new Date()
      }
    })
  }
  
  async findActiveUsersByDomain(domain: string): Promise<User[]> {
    const entities = await this.db.users.findMany({
      where: {
        email: { endsWith: `@${domain}` },
        status: 'active'
      },
      orderBy: { createdAt: 'desc' }
    })
    
    return entities.map(UserMapper.toDomain)
  }
}
```

### Query Builders

```elixir
defmodule Shell.UserQueries do
  import Ecto.Query
  alias Shell.Schemas.UserSchema
  
  @doc """
  Base query with common preloads
  """
  def base_query do
    from(u in UserSchema,
      preload: [:profile, :preferences]
    )
  end
  
  @doc """
  Find users by various criteria
  """
  def by_email(query \\ base_query(), email) do
    from(u in query,
      where: u.email == ^email
    )
  end
  
  def active(query \\ base_query()) do
    from(u in query,
      where: u.status == "active"
    )
  end
  
  def created_between(query \\ base_query(), start_date, end_date) do
    from(u in query,
      where: u.created_at >= ^start_date,
      where: u.created_at <= ^end_date
    )
  end
  
  def with_domain(query \\ base_query(), domain) do
    from(u in query,
      where: like(u.email, ^"%@#{domain}")
    )
  end
  
  # Composable queries
  def recent_active_users(domain, days_back \\ 30) do
    start_date = DateTime.utc_now() |> DateTime.add(-days_back, :day)
    
    base_query()
    |> active()
    |> with_domain(domain)
    |> created_between(start_date, DateTime.utc_now())
    |> order_by([u], desc: u.created_at)
  end
end
```

## Transaction Management

### Transactional Boundaries

```kotlin
@Service
class OrderService(
    private val orderRepository: OrderRepository,
    private val inventoryRepository: InventoryRepository,
    private val paymentRepository: PaymentRepository
) {
    @Transactional
    suspend fun createOrder(command: CreateOrderCommand): Result<Order, OrderError> {
        // Start transaction
        
        // 1. Validate using functional core
        val validationResult = OrderCore.validate(command)
        if (validationResult is Failure) {
            return validationResult
        }
        
        // 2. Check inventory (read)
        val inventory = inventoryRepository.checkAvailability(command.items)
        val inventoryResult = OrderCore.validateInventory(command.items, inventory)
        if (inventoryResult is Failure) {
            return inventoryResult
        }
        
        // 3. Create order using functional core
        val order = OrderCore.create(command)
        
        // 4. Reserve inventory (write)
        inventoryRepository.reserve(order.id, order.items)
        
        // 5. Save order (write)
        orderRepository.save(order)
        
        // 6. Process payment asynchronously (outside transaction)
        publishEvent(ProcessPaymentCommand(order.id, command.paymentMethod))
        
        return Success(order)
        // Transaction commits here
    }
    
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    suspend fun compensateOrder(orderId: OrderId, reason: String) {
        // Separate transaction for compensation
        val order = orderRepository.findById(orderId) ?: return
        inventoryRepository.release(orderId)
        orderRepository.save(order.cancel(reason))
    }
}
```

### Optimistic Locking

```typescript
// Include version in domain model for concurrency control
interface VersionedEntity {
  readonly version: number
}

export class SqlOrderRepository {
  async save(order: Order & VersionedEntity): Promise<void> {
    const result = await this.db.orders.update({
      where: {
        id: order.id,
        version: order.version // Optimistic lock check
      },
      data: {
        ...OrderMapper.toEntity(order),
        version: { increment: 1 }
      }
    })
    
    if (result.count === 0) {
      throw new OptimisticLockError(
        `Order ${order.id} was modified by another process`
      )
    }
  }
}

// Retry logic in service layer
export class OrderService {
  async updateOrder(
    id: OrderId,
    updates: OrderUpdate
  ): Promise<Result<Order, OrderError>> {
    const maxRetries = 3
    
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        const order = await this.orderRepo.findById(id)
        if (!order) return err({ kind: 'NotFound' })
        
        const updated = OrderCore.update(order, updates)
        if (updated.kind === 'err') return updated
        
        await this.orderRepo.save(updated.value)
        return ok(updated.value)
        
      } catch (error) {
        if (error instanceof OptimisticLockError && attempt < maxRetries - 1) {
          continue // Retry
        }
        throw error
      }
    }
    
    return err({ kind: 'ConcurrentModification' })
  }
}
```

## Migration Patterns

### Safe Schema Evolution

```sql
-- Migration: Add new payment methods
-- Step 1: Add column with default (safe)
ALTER TABLE orders 
ADD COLUMN payment_method VARCHAR(50) DEFAULT 'credit_card';

-- Step 2: Backfill existing data
UPDATE orders 
SET payment_method = 
  CASE 
    WHEN payment_type = 1 THEN 'credit_card'
    WHEN payment_type = 2 THEN 'paypal'
    ELSE 'unknown'
  END
WHERE payment_method IS NULL;

-- Step 3: Add constraint after backfill
ALTER TABLE orders 
ALTER COLUMN payment_method SET NOT NULL;

ALTER TABLE orders
ADD CONSTRAINT chk_payment_method 
CHECK (payment_method IN ('credit_card', 'paypal', 'bank_transfer', 'crypto'));

-- Step 4: Remove old column (after code deployment)
-- Run this in a separate migration after confirming new code is stable
ALTER TABLE orders DROP COLUMN payment_type;
```

### Zero-Downtime Migrations

```elixir
defmodule MyApp.Repo.Migrations.AddUserPreferences do
  use Ecto.Migration
  
  def up do
    # Create new table without foreign key first
    create table(:user_preferences) do
      add :user_id, :uuid, null: false
      add :theme, :string, default: "light"
      add :notifications, :map, default: %{}
      timestamps()
    end
    
    # Add index before foreign key
    create index(:user_preferences, [:user_id])
    
    # Add foreign key without validation initially
    execute """
    ALTER TABLE user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id)
    NOT VALID;
    """
    
    # Validate constraint in background
    execute """
    ALTER TABLE user_preferences
    VALIDATE CONSTRAINT user_preferences_user_id_fkey;
    """
  end
  
  def down do
    drop table(:user_preferences)
  end
end
```

## Query Optimization

### Efficient Pagination Queries

```kotlin
// Cursor-based pagination for large datasets
data class Cursor(
    val id: UUID,
    val createdAt: Instant
)

@Repository
class OrderRepository {
    @Query("""
        SELECT o FROM OrderEntity o
        WHERE (o.createdAt < :createdAt 
           OR (o.createdAt = :createdAt AND o.id < :id))
        AND o.status = :status
        ORDER BY o.createdAt DESC, o.id DESC
        LIMIT :limit
    """)
    fun findOrdersAfterCursor(
        createdAt: Instant,
        id: UUID,
        status: String,
        limit: Int
    ): List<OrderEntity>
    
    fun getOrderPage(
        cursor: Cursor?,
        status: OrderStatus,
        pageSize: Int
    ): Page<Order> {
        val entities = if (cursor == null) {
            // First page
            findOrdersByStatusOrderByCreatedAtDesc(
                status.toString(),
                PageRequest.of(0, pageSize + 1)
            )
        } else {
            // Subsequent pages
            findOrdersAfterCursor(
                cursor.createdAt,
                cursor.id,
                status.toString(),
                pageSize + 1
            )
        }
        
        val hasMore = entities.size > pageSize
        val items = entities.take(pageSize).map(OrderMapper::toDomain)
        val nextCursor = if (hasMore) {
            val last = items.last()
            Cursor(last.id.toUUID(), last.createdAt)
        } else null
        
        return Page(items, nextCursor, hasMore)
    }
}
```

### N+1 Query Prevention

```typescript
// Bad: N+1 queries
export class NaiveOrderRepository {
  async findOrdersWithItems(customerId: CustomerId): Promise<Order[]> {
    const orders = await this.db.orders.findMany({
      where: { customerId: customerId.value }
    })
    
    // This causes N+1 queries!
    return Promise.all(orders.map(async order => {
      const items = await this.db.orderItems.findMany({
        where: { orderId: order.id }
      })
      return OrderMapper.toDomain(order, items)
    }))
  }
}

// Good: Eager loading
export class OptimizedOrderRepository {
  async findOrdersWithItems(customerId: CustomerId): Promise<Order[]> {
    const orders = await this.db.orders.findMany({
      where: { customerId: customerId.value },
      include: {
        items: {
          include: {
            product: true
          }
        }
      }
    })
    
    return orders.map(OrderMapper.toDomain)
  }
  
  // Alternative: Manual join for complex queries
  async findOrderStats(customerId: CustomerId): Promise<OrderStats[]> {
    const stats = await this.db.$queryRaw`
      SELECT 
        o.id,
        o.created_at,
        COUNT(oi.id) as item_count,
        SUM(oi.quantity * oi.price) as total_amount
      FROM orders o
      LEFT JOIN order_items oi ON oi.order_id = o.id
      WHERE o.customer_id = ${customerId.value}
      GROUP BY o.id, o.created_at
      ORDER BY o.created_at DESC
    `
    
    return stats.map(OrderStatsMapper.toDomain)
  }
}
```

### Database-Specific Optimizations

```elixir
defmodule Shell.OptimizedQueries do
  import Ecto.Query
  
  # Use database-specific features when beneficial
  def search_products(search_term) do
    from(p in Product,
      # PostgreSQL full-text search
      where: fragment("to_tsvector('english', ?) @@ plainto_tsquery('english', ?)", 
        p.name, ^search_term),
      # Add relevance ranking
      order_by: fragment("ts_rank(to_tsvector('english', ?), plainto_tsquery('english', ?))",
        p.name, ^search_term)
    )
  end
  
  # Use JSONB for flexible schema
  def find_by_metadata(key, value) do
    from(p in Product,
      where: fragment("metadata @> ?", %{^key => ^value})
    )
  end
  
  # Efficient bulk operations
  def bulk_update_status(product_ids, new_status) do
    from(p in Product,
      where: p.id in ^product_ids,
      update: [set: [status: ^new_status, updated_at: ^DateTime.utc_now()]]
    )
    |> Repo.update_all([])
  end
end
```

## Event Sourcing Patterns

### Event Store Schema

```sql
-- Event store for audit and event sourcing
CREATE TABLE domain_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_id UUID NOT NULL,
    aggregate_type VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_version INTEGER NOT NULL,
    event_data JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ensure event ordering per aggregate
    UNIQUE(aggregate_id, event_version),
    INDEX idx_events_aggregate (aggregate_id, event_version),
    INDEX idx_events_type_created (event_type, created_at DESC)
);

-- Snapshots for performance
CREATE TABLE aggregate_snapshots (
    aggregate_id UUID PRIMARY KEY,
    aggregate_type VARCHAR(100) NOT NULL,
    snapshot_data JSONB NOT NULL,
    event_version INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    INDEX idx_snapshots_type (aggregate_type)
);
```

### Event Repository

```kotlin
@Component
class EventStore(
    private val jdbcTemplate: JdbcTemplate,
    private val objectMapper: ObjectMapper
) {
    fun saveEvents(aggregateId: UUID, events: List<DomainEvent>, expectedVersion: Int) {
        val sql = """
            INSERT INTO domain_events 
            (aggregate_id, aggregate_type, event_type, event_version, event_data, metadata)
            VALUES (?, ?, ?, ?, ?::jsonb, ?::jsonb)
        """
        
        jdbcTemplate.batchUpdate(sql,
            events.mapIndexed { index, event ->
                arrayOf(
                    aggregateId,
                    event.aggregateType,
                    event::class.simpleName,
                    expectedVersion + index + 1,
                    objectMapper.writeValueAsString(event),
                    objectMapper.writeValueAsString(event.metadata)
                )
            }
        )
    }
    
    fun loadEvents(aggregateId: UUID, fromVersion: Int = 0): List<StoredEvent> {
        return jdbcTemplate.query(
            """
            SELECT * FROM domain_events 
            WHERE aggregate_id = ? AND event_version > ?
            ORDER BY event_version
            """,
            { rs, _ ->
                StoredEvent(
                    id = rs.getObject("id", UUID::class.java),
                    aggregateId = rs.getObject("aggregate_id", UUID::class.java),
                    eventType = rs.getString("event_type"),
                    eventVersion = rs.getInt("event_version"),
                    eventData = rs.getString("event_data"),
                    metadata = rs.getString("metadata"),
                    createdAt = rs.getTimestamp("created_at").toInstant()
                )
            },
            aggregateId,
            fromVersion
        )
    }
    
    fun saveSnapshot(aggregateId: UUID, aggregate: Any, version: Int) {
        jdbcTemplate.update(
            """
            INSERT INTO aggregate_snapshots 
            (aggregate_id, aggregate_type, snapshot_data, event_version)
            VALUES (?, ?, ?::jsonb, ?)
            ON CONFLICT (aggregate_id) 
            DO UPDATE SET 
                snapshot_data = EXCLUDED.snapshot_data,
                event_version = EXCLUDED.event_version,
                created_at = NOW()
            """,
            aggregateId,
            aggregate::class.simpleName,
            objectMapper.writeValueAsString(aggregate),
            version
        )
    }
}
```

## Denormalization Strategies

### Read Models

```typescript
// Denormalized read model for performance
interface OrderSummaryReadModel {
  readonly orderId: string
  readonly customerId: string
  readonly customerName: string
  readonly customerEmail: string
  readonly totalAmount: number
  readonly currency: string
  readonly itemCount: number
  readonly status: string
  readonly createdAt: Date
  readonly lastModifiedAt: Date
}

// Projection that maintains the read model
export class OrderProjection {
  constructor(
    private readDb: ReadModelDatabase,
    private eventBus: EventBus
  ) {
    eventBus.subscribe('OrderCreated', this.handleOrderCreated.bind(this))
    eventBus.subscribe('OrderItemAdded', this.handleItemAdded.bind(this))
    eventBus.subscribe('OrderStatusChanged', this.handleStatusChanged.bind(this))
  }
  
  private async handleOrderCreated(event: OrderCreatedEvent): Promise<void> {
    const customer = await this.readDb.customers.findById(event.customerId)
    
    await this.readDb.orderSummaries.create({
      orderId: event.orderId,
      customerId: event.customerId,
      customerName: customer.name,
      customerEmail: customer.email,
      totalAmount: 0,
      currency: event.currency,
      itemCount: 0,
      status: 'created',
      createdAt: event.timestamp,
      lastModifiedAt: event.timestamp
    })
  }
  
  private async handleItemAdded(event: OrderItemAddedEvent): Promise<void> {
    await this.readDb.orderSummaries.update(event.orderId, {
      $inc: {
        totalAmount: event.price * event.quantity,
        itemCount: event.quantity
      },
      $set: {
        lastModifiedAt: event.timestamp
      }
    })
  }
}
```

### Materialized Views

```sql
-- Materialized view for reporting
CREATE MATERIALIZED VIEW customer_order_stats AS
SELECT 
    c.id as customer_id,
    c.email,
    COUNT(DISTINCT o.id) as total_orders,
    COUNT(DISTINCT CASE WHEN o.status = 'completed' THEN o.id END) as completed_orders,
    SUM(CASE WHEN o.status = 'completed' THEN o.total_amount ELSE 0 END) as lifetime_value,
    AVG(CASE WHEN o.status = 'completed' THEN o.total_amount ELSE NULL END) as avg_order_value,
    MAX(o.created_at) as last_order_date,
    MIN(o.created_at) as first_order_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.email;

-- Index for fast lookups
CREATE INDEX idx_customer_order_stats_email ON customer_order_stats(email);
CREATE INDEX idx_customer_order_stats_value ON customer_order_stats(lifetime_value DESC);

-- Refresh strategy
CREATE OR REPLACE FUNCTION refresh_customer_stats()
RETURNS void AS $
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY customer_order_stats;
END;
$ LANGUAGE plpgsql;

-- Schedule refresh (using pg_cron or similar)
SELECT cron.schedule('refresh-customer-stats', '*/15 * * * *', 'SELECT refresh_customer_stats()');
```

## Testing Database Code

### Repository Testing

```elixir
defmodule Shell.UserRepositoryTest do
  use MyApp.DataCase
  
  alias Shell.UserRepository
  alias Core.User
  
  describe "find_by_email/1" do
    test "returns user when exists" do
      user = insert(:user, email: "test@example.com")
      
      assert {:ok, found} = UserRepository.find_by_email("test@example.com")
      assert found.id == user.id
      assert found.email == user.email
    end
    
    test "returns error when not found" do
      assert {:error, :not_found} = UserRepository.find_by_email("nonexistent@example.com")
    end
    
    test "is case insensitive" do
      insert(:user, email: "Test@Example.com")
      
      assert {:ok, _} = UserRepository.find_by_email("test@example.com")
      assert {:ok, _} = UserRepository.find_by_email("TEST@EXAMPLE.COM")
    end
  end
  
  describe "concurrent updates" do
    test "handles optimistic locking correctly" do
      user = insert(:user)
      
      # Simulate concurrent updates
      {:ok, user1} = UserRepository.find_by_id(user.id)
      {:ok, user2} = UserRepository.find_by_id(user.id)
      
      # First update succeeds
      updated1 = User.update_profile(user1, %{bio: "Update 1"})
      assert {:ok, _} = UserRepository.save(updated1)
      
      # Second update fails due to version mismatch
      updated2 = User.update_profile(user2, %{bio: "Update 2"})
      assert {:error, :stale_object} = UserRepository.save(updated2)
    end
  end
end
```

## Performance Monitoring

```kotlin
// Add query logging and metrics
@Component
class InstrumentedOrderRepository(
    private val delegate: OrderRepository,
    private val meterRegistry: MeterRegistry
) : OrderRepository {
    
    override suspend fun findById(id: OrderId): Order? {
        return measureTimedValue {
            delegate.findById(id)
        }.also { (result, duration) ->
            meterRegistry.timer("db.query", 
                "table", "orders",
                "operation", "findById"
            ).record(duration)
            
            if (result == null) {
                meterRegistry.counter("db.query.miss",
                    "table", "orders"
                ).increment()
            }
        }.value
    }
    
    override suspend fun findOrdersInDateRange(
        start: Instant,
        end: Instant,
        limit: Int
    ): List<Order> {
        val timer = Timer.start()
        
        return try {
            delegate.findOrdersInDateRange(start, end, limit).also { results ->
                val duration = timer.stop()
                
                if (duration > Duration.ofSeconds(1)) {
                    logger.warn(
                        "Slow query detected: findOrdersInDateRange took ${duration.toMillis()}ms",
                        "start" to start,
                        "end" to end,
                        "limit" to limit,
                        "resultCount" to results.size
                    )
                }
                
                meterRegistry.summary("db.query.resultSize",
                    "table", "orders"
                ).record(results.size.toDouble())
            }
        } catch (e: Exception) {
            meterRegistry.counter("db.query.error",
                "table", "orders",
                "operation", "findOrdersInDateRange"
            ).increment()
            throw e
        }
    }
}
```

## Database Best Practices

- [ ] Domain models are completely isolated from database schemas
- [ ] Repositories return domain types, not database entities
- [ ] Transactions are managed at service boundaries
- [ ] Optimistic locking prevents lost updates
- [ ] Migrations are backwards compatible
- [ ] Queries are optimized to prevent N+1 problems
- [ ] Indexes support common query patterns
- [ ] Read models are denormalized appropriately
- [ ] Database-specific features are isolated to repositories
- [ ] All repository methods are tested with real database