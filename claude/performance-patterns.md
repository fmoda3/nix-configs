# Performance Patterns

## Core Principles

Performance optimization should maintain the functional core's purity. Optimize at the architectural level first, then the implementation level. The functional core's immutability and lack of side effects make many optimizations straightforward.

## Functional Core Performance

### Memoization for Pure Functions

```kotlin
// Memoize expensive pure computations
class MemoizedPriceCalculator {
    private val cache = ConcurrentHashMap<CacheKey, Money>()
    
    data class CacheKey(
        val items: List<OrderItem>,
        val discounts: List<Discount>,
        val taxRate: TaxRate
    )
    
    fun calculateTotal(
        items: List<OrderItem>,
        discounts: List<Discount>,
        taxRate: TaxRate
    ): Money {
        val key = CacheKey(items, discounts, taxRate)
        
        return cache.getOrPut(key) {
            // Expensive calculation only runs if not cached
            val subtotal = items.sumOf { it.price * it.quantity }
            val discounted = discounts.fold(subtotal) { acc, discount ->
                discount.apply(acc)
            }
            val tax = discounted * taxRate.value
            discounted + tax
        }
    }
    
    // Cache invalidation isn't needed for pure functions!
    // Results are always the same for the same inputs
}

// Thread-safe memoization with size limits
class BoundedMemoizer<K, V>(
    private val maxSize: Int = 1000,
    private val compute: (K) -> V
) {
    private val cache = Collections.synchronizedMap(
        object : LinkedHashMap<K, V>(16, 0.75f, true) {
            override fun removeEldestEntry(eldest: Map.Entry<K, V>) = size > maxSize
        }
    )
    
    fun get(key: K): V = cache.getOrPut(key) { compute(key) }
}
```

### Lazy Evaluation

```typescript
// Lazy evaluation for expensive computations
export class LazyValue<T> {
  private computed = false
  private value?: T
  
  constructor(private readonly compute: () => T) {}
  
  get(): T {
    if (!this.computed) {
      this.value = this.compute()
      this.computed = true
    }
    return this.value!
  }
}

// Lazy computed properties in domain models
export class Order {
  private readonly _totals = new LazyValue(() => 
    OrderCalculator.calculateTotals(this.items, this.discounts)
  )
  
  constructor(
    readonly id: OrderId,
    readonly items: readonly OrderItem[],
    readonly discounts: readonly Discount[]
  ) {}
  
  get totals(): OrderTotals {
    return this._totals.get()
  }
}

// Lazy streams for large datasets
export function* lazyMap<T, U>(
  items: Iterable<T>,
  fn: (item: T) => U
): Generator<U> {
  for (const item of items) {
    yield fn(item)
  }
}

export function* lazyFilter<T>(
  items: Iterable<T>,
  predicate: (item: T) => boolean
): Generator<T> {
  for (const item of items) {
    if (predicate(item)) yield item
  }
}

// Usage - only processes what's needed
const results = pipe(
  hugeDataset,
  items => lazyFilter(items, item => item.isActive),
  items => lazyMap(items, item => item.transform()),
  items => take(items, 100) // Only processes first 100
)
```

### Structural Sharing

```elixir
# Efficient immutable updates with structural sharing
defmodule Core.EfficientList do
  @moduledoc """
  List operations that maximize structural sharing
  """
  
  def update_at(list, index, fun) do
    {before, [item | after_]} = Enum.split(list, index)
    before ++ [fun.(item)] ++ after_
  end
  
  # Use maps for frequent updates
  defmodule IndexedList do
    defstruct items: %{}, size: 0, next_index: 0
    
    def new(items \\ []) do
      indexed = items
      |> Enum.with_index()
      |> Enum.into(%{}, fn {item, idx} -> {idx, item} end)
      
      %__MODULE__{
        items: indexed,
        size: map_size(indexed),
        next_index: map_size(indexed)
      }
    end
    
    def update(list, index, fun) do
      case Map.fetch(list.items, index) do
        {:ok, item} ->
          # Structural sharing - only changed item is new
          %{list | items: Map.put(list.items, index, fun.(item))}
        :error ->
          list
      end
    end
    
    def to_list(%__MODULE__{items: items, size: size}) do
      for i <- 0..(size - 1), do: items[i]
    end
  end
end

# Persistent data structures
defmodule Core.PersistentMap do
  # Use libraries like persistent_ets for truly persistent data structures
  # that share structure across versions
  
  def put(map, key, value) do
    # Returns new version sharing most structure with original
    :persistent_term.put({map.id, map.version + 1}, 
      Map.put(map.data, key, value))
    %{map | version: map.version + 1}
  end
end
```

## Concurrency Patterns

### Parallel Processing in Functional Core

```kotlin
// Parallel processing of independent computations
object OrderProcessor {
    private val computePool = ForkJoinPool(
        Runtime.getRuntime().availableProcessors()
    )
    
    suspend fun processOrders(orders: List<Order>): List<ProcessedOrder> {
        return coroutineScope {
            orders.map { order ->
                async(computePool.asCoroutineDispatcher()) {
                    // Each order processed in parallel
                    processOrder(order)
                }
            }.awaitAll()
        }
    }
    
    // Pure function - safe to parallelize
    private fun processOrder(order: Order): ProcessedOrder {
        val validationResult = validateOrder(order)
        val pricingResult = calculatePricing(order)
        val inventoryResult = checkInventory(order)
        
        return ProcessedOrder(
            order = order,
            validation = validationResult,
            pricing = pricingResult,
            inventory = inventoryResult
        )
    }
    
    // Batch processing with chunking
    fun processBatch(items: List<Item>, chunkSize: Int = 1000): List<Result> {
        return items.chunked(chunkSize)
            .parallelStream()
            .flatMap { chunk ->
                chunk.map { processItem(it) }.stream()
            }
            .collect(Collectors.toList())
    }
}
```

### Actor Model for Stateful Processing

```elixir
defmodule Shell.OrderProcessor do
  use GenServer
  
  # State includes both processing queue and results cache
  defstruct queue: :queue.new(), 
            processing: %{}, 
            cache: %{},
            max_concurrent: 10
  
  def process_order(order_id) do
    GenServer.call(__MODULE__, {:process, order_id})
  end
  
  @impl true
  def handle_call({:process, order_id}, from, state) do
    # Check cache first
    case Map.get(state.cache, order_id) do
      nil ->
        # Add to queue if not cached
        new_state = %{state | 
          queue: :queue.in({order_id, from}, state.queue)
        }
        {:noreply, new_state, {:continue, :process_queue}}
      
      result ->
        # Return cached result immediately
        {:reply, result, state}
    end
  end
  
  @impl true
  def handle_continue(:process_queue, state) do
    if map_size(state.processing) < state.max_concurrent do
      case :queue.out(state.queue) do
        {{:value, {order_id, from}}, new_queue} ->
          # Start async processing
          task = Task.async(fn -> 
            Core.OrderProcessor.process(order_id)
          end)
          
          new_state = %{state |
            queue: new_queue,
            processing: Map.put(state.processing, task.ref, {order_id, from})
          }
          
          {:noreply, new_state}
        
        {:empty, _} ->
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end
  
  @impl true
  def handle_info({ref, result}, state) when is_reference(ref) do
    case Map.pop(state.processing, ref) do
      {{order_id, from}, new_processing} ->
        # Cache result
        new_cache = Map.put(state.cache, order_id, result)
        
        # Reply to caller
        GenServer.reply(from, result)
        
        # Clean up task
        Process.demonitor(ref, [:flush])
        
        new_state = %{state |
          processing: new_processing,
          cache: new_cache
        }
        
        # Process more from queue
        {:noreply, new_state, {:continue, :process_queue}}
      
      {nil, _} ->
        {:noreply, state}
    end
  end
end
```

## Caching Strategies

### Multi-Level Caching

```typescript
interface CacheLevel<K, V> {
  get(key: K): Promise<V | undefined>
  set(key: K, value: V, ttl?: number): Promise<void>
  delete(key: K): Promise<void>
}

export class MultiLevelCache<K, V> {
  constructor(
    private levels: CacheLevel<K, V>[],
    private compute: (key: K) => Promise<V>
  ) {}
  
  async get(key: K): Promise<V> {
    // Try each cache level
    for (let i = 0; i < this.levels.length; i++) {
      const value = await this.levels[i].get(key)
      
      if (value !== undefined) {
        // Populate higher levels on cache hit
        for (let j = 0; j < i; j++) {
          await this.levels[j].set(key, value)
        }
        return value
      }
    }
    
    // Compute if not in any cache
    const value = await this.compute(key)
    
    // Populate all cache levels
    await Promise.all(
      this.levels.map(level => level.set(key, value))
    )
    
    return value
  }
}

// Usage
const cache = new MultiLevelCache<UserId, User>([
  new InMemoryCache({ maxSize: 1000, ttl: 60 }), // L1: 1 minute
  new RedisCache({ ttl: 3600 }), // L2: 1 hour  
  new DatabaseCache({ ttl: 86400 }) // L3: 1 day
], userId => userRepository.findById(userId))

// Smart cache key generation
export class CacheKeyBuilder {
  static forUser(id: UserId): string {
    return `user:${id.value}`
  }
  
  static forOrderList(filters: OrderFilters): string {
    // Consistent key generation for complex queries
    const normalized = {
      status: filters.status || 'all',
      customerId: filters.customerId || 'all',
      dateFrom: filters.dateFrom?.toISOString() || 'any',
      dateTo: filters.dateTo?.toISOString() || 'any',
      page: filters.page || 1,
      limit: filters.limit || 20
    }
    
    return `orders:${JSON.stringify(normalized)}`
  }
}
```

### Cache Warming and Invalidation

```kotlin
@Component
class CacheWarmer(
    private val cache: CacheManager,
    private val userRepository: UserRepository,
    private val orderRepository: OrderRepository
) {
    @EventListener(ApplicationReadyEvent::class)
    fun warmCachesOnStartup() {
        runBlocking {
            launch { warmFrequentUsers() }
            launch { warmRecentOrders() }
            launch { warmReferenceData() }
        }
    }
    
    private suspend fun warmFrequentUsers() {
        val frequentUserIds = userRepository.findMostActiveUserIds(limit = 1000)
        
        frequentUserIds.chunked(100).forEach { chunk ->
            coroutineScope {
                chunk.map { userId ->
                    async {
                        val user = userRepository.findById(userId)
                        user?.let { cache.put("user:$userId", it) }
                    }
                }.awaitAll()
            }
        }
    }
    
    // Intelligent invalidation
    @EventListener
    fun handleUserUpdated(event: UserUpdatedEvent) {
        // Invalidate specific caches
        cache.evict("user:${event.userId}")
        cache.evict("user:email:${event.oldEmail}")
        cache.evict("user:email:${event.newEmail}")
        
        // Invalidate dependent caches
        cache.evictAllMatching("orders:user:${event.userId}:*")
    }
}
```

## Database Performance

### Connection Pooling

```elixir
# Optimal connection pool configuration
config :my_app, MyApp.Repo,
  pool_size: System.get_env("POOL_SIZE", "20") |> String.to_integer(),
  queue_target: 50,
  queue_interval: 1000,
  # Separate pools for read/write
  read_replica: [
    hostname: System.get_env("READ_REPLICA_HOST"),
    pool_size: System.get_env("READ_POOL_SIZE", "40") |> String.to_integer()
  ]

defmodule Shell.ReadWriteSplit do
  @doc """
  Route queries to appropriate database
  """
  defmacro read_query(queryable, opts \\ []) do
    quote do
      unquote(queryable)
      |> Repo.all([{:prefix, "read_replica"} | unquote(opts)])
    end
  end
  
  defmacro write_query(queryable, opts \\ []) do
    quote do
      unquote(queryable)
      |> Repo.all([{:prefix, "primary"} | unquote(opts)])
    end
  end
end
```

### Batch Operations

```typescript
export class BatchProcessor<T, R> {
  private batch: T[] = []
  private timer?: NodeJS.Timeout
  
  constructor(
    private readonly processFn: (items: T[]) => Promise<R[]>,
    private readonly options: {
      maxBatchSize: number
      maxWaitTime: number
    }
  ) {}
  
  async add(item: T): Promise<R> {
    return new Promise((resolve, reject) => {
      this.batch.push(item)
      
      if (this.batch.length >= this.options.maxBatchSize) {
        this.flush()
      } else if (!this.timer) {
        this.timer = setTimeout(() => this.flush(), this.options.maxWaitTime)
      }
      
      // Store resolver to call when batch processes
      this.resolvers.set(item, { resolve, reject })
    })
  }
  
  private async flush() {
    if (this.batch.length === 0) return
    
    const items = [...this.batch]
    const resolvers = new Map(this.resolvers)
    
    this.batch = []
    this.resolvers.clear()
    if (this.timer) {
      clearTimeout(this.timer)
      this.timer = undefined
    }
    
    try {
      const results = await this.processFn(items)
      
      items.forEach((item, index) => {
        const resolver = resolvers.get(item)
        resolver?.resolve(results[index])
      })
    } catch (error) {
      resolvers.forEach(resolver => resolver.reject(error))
    }
  }
  
  private resolvers = new Map<T, {
    resolve: (value: R) => void
    reject: (error: any) => void
  }>()
}

// Usage for database operations
const userLoader = new BatchProcessor(
  async (userIds: string[]) => {
    // Single query for multiple users
    return db.users.findMany({
      where: { id: { in: userIds } }
    })
  },
  { maxBatchSize: 100, maxWaitTime: 10 }
)

// Individual calls are automatically batched
const user1 = await userLoader.add("user-1")
const user2 = await userLoader.add("user-2")
```

## Memory Management

### Efficient Data Structures

```kotlin
// Use appropriate data structures for performance
object EfficientCollections {
    // Primitive collections to avoid boxing
    fun calculateSum(values: IntArray): Int {
        var sum = 0
        for (value in values) {
            sum += value
        }
        return sum
    }
    
    // Specialized collections for memory efficiency
    class CompactUserIndex {
        // Store user data in columnar format
        private val ids = mutableListOf<UserId>()
        private val emails = mutableListOf<String>()
        private val statuses = mutableListOf<UserStatus>()
        
        fun add(user: User) {
            ids.add(user.id)
            emails.add(user.email.value)
            statuses.add(user.status)
        }
        
        fun findByEmail(email: String): User? {
            val index = emails.indexOf(email)
            return if (index >= 0) {
                User(
                    id = ids[index],
                    email = Email(emails[index]),
                    status = statuses[index]
                )
            } else null
        }
    }
    
    // Flyweight pattern for common values
    object MoneyCache {
        private val cache = ConcurrentHashMap<Pair<Int, Currency>, Money>()
        
        fun of(amount: Int, currency: Currency): Money {
            return cache.getOrPut(amount to currency) {
                Money(amount, currency)
            }
        }
    }
}
```

### Stream Processing

```elixir
defmodule Core.StreamProcessor do
  @doc """
  Process large files without loading into memory
  """
  def process_large_csv(file_path, processor_fn) do
    file_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Stream.map(&processor_fn/1)
    |> Stream.chunk_every(1000)
    |> Stream.each(&batch_save/1)
    |> Stream.run()
  end
  
  @doc """
  Memory-efficient aggregation
  """
  def aggregate_orders(order_stream) do
    order_stream
    |> Stream.transform(
      %{total: 0, count: 0, by_status: %{}},
      fn order, acc ->
        new_acc = %{
          total: acc.total + order.amount,
          count: acc.count + 1,
          by_status: Map.update(
            acc.by_status,
            order.status,
            1,
            &(&1 + 1)
          )
        }
        {[new_acc], new_acc}
      end
    )
    |> Stream.take(-1)  # Only keep final result
    |> Enum.to_list()
    |> List.first()
  end
  
  @doc """
  Backpressure handling
  """
  def process_with_backpressure(source_stream, process_fn, max_concurrent) do
    source_stream
    |> Stream.chunk_every(max_concurrent)
    |> Stream.flat_map(fn chunk ->
      chunk
      |> Enum.map(&Task.async(fn -> process_fn.(&1) end))
      |> Enum.map(&Task.await/1)
    end)
  end
end
```

## HTTP Performance

### Connection Pooling and Reuse

```typescript
// Efficient HTTP client configuration
import { Agent } from 'http'

const httpAgent = new Agent({
  keepAlive: true,
  keepAliveMsecs: 1000,
  maxSockets: 50,
  maxFreeSockets: 10
})

export class OptimizedHttpClient {
  private readonly client = axios.create({
    httpAgent,
    timeout: 5000,
    // Enable compression
    headers: {
      'Accept-Encoding': 'gzip, deflate'
    }
  })
  
  // Circuit breaker for resilience
  private readonly circuitBreaker = new CircuitBreaker(
    async (url: string) => this.client.get(url),
    {
      timeout: 3000,
      errorThresholdPercentage: 50,
      resetTimeout: 30000
    }
  )
  
  async get(url: string): Promise<any> {
    const cacheKey = `http:${url}`
    
    // Check cache first
    const cached = await cache.get(cacheKey)
    if (cached) return cached
    
    // Use circuit breaker
    const response = await this.circuitBreaker.fire(url)
    
    // Cache successful responses
    if (response.status === 200) {
      const ttl = this.extractCacheTTL(response.headers)
      await cache.set(cacheKey, response.data, ttl)
    }
    
    return response.data
  }
  
  private extractCacheTTL(headers: any): number {
    const cacheControl = headers['cache-control']
    if (!cacheControl) return 60
    
    const maxAge = cacheControl.match(/max-age=(\d+)/)
    return maxAge ? parseInt(maxAge[1]) : 60
  }
}
```

### Response Compression

```kotlin
@Configuration
class CompressionConfig {
    @Bean
    fun gzipFilter(): Filter {
        return GzipCompressingFilter().apply {
            setMinGzipSize(1024) // Only compress responses > 1KB
            setIncludedMimeTypes(
                "application/json",
                "application/xml",
                "text/html",
                "text/plain"
            )
        }
    }
}

// Streaming responses for large datasets
@RestController
class StreamingController {
    @GetMapping("/api/orders/export", produces = ["application/x-ndjson"])
    fun exportOrders(
        @RequestParam customerId: String?,
        response: HttpServletResponse
    ): ResponseEntity<StreamingResponseBody> {
        
        val streaming = StreamingResponseBody { output ->
            val writer = output.bufferedWriter()
            
            orderRepository.streamOrders(customerId).use { stream ->
                stream.forEach { order ->
                    writer.write(Json.encodeToString(order))
                    writer.newLine()
                    writer.flush()
                }
            }
        }
        
        return ResponseEntity.ok()
            .header("Content-Type", "application/x-ndjson")
            .header("Cache-Control", "no-cache")
            .body(streaming)
    }
}
```

## Monitoring and Profiling

### Performance Metrics

```elixir
defmodule Shell.PerformanceMonitor do
  use Prometheus.PlugExporter
  
  def setup do
    # Define metrics
    Histogram.new([
      name: :http_request_duration_seconds,
      help: "HTTP request duration",
      labels: [:method, :path, :status],
      buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
    ])
    
    Counter.new([
      name: :domain_operation_total,
      help: "Domain operation count",
      labels: [:operation, :status]
    ])
    
    Gauge.new([
      name: :cache_size,
      help: "Current cache size",
      labels: [:cache_name]
    ])
  end
  
  defmacro measure(operation, do: block) do
    quote do
      start_time = System.monotonic_time()
      
      try do
        result = unquote(block)
        
        duration = System.monotonic_time() - start_time
        :telemetry.execute(
          [:my_app, :operation, :complete],
          %{duration: duration},
          %{operation: unquote(operation), status: :success}
        )
        
        Counter.inc([name: :domain_operation_total, labels: [unquote(operation), "success"]])
        
        result
      rescue
        error ->
          duration = System.monotonic_time() - start_time
          
          :telemetry.execute(
            [:my_app, :operation, :error],
            %{duration: duration},
            %{operation: unquote(operation), error: error}
          )
          
          Counter.inc([name: :domain_operation_total, labels: [unquote(operation), "error"]])
          
          reraise error, __STACKTRACE__
      end
    end
  end
end

# Usage
defmodule Core.OrderService do
  import Shell.PerformanceMonitor
  
  def process_order(order) do
    measure :process_order do
      order
      |> validate()
      |> calculate_pricing()
      |> apply_discounts()
    end
  end
end
```

### Profiling and Optimization

```typescript
// Performance profiling utilities
export class PerformanceProfiler {
  private static marks = new Map<string, number>()
  
  static mark(name: string): void {
    this.marks.set(name, performance.now())
  }
  
  static measure(name: string, startMark: string, endMark?: string): number {
    const start = this.marks.get(startMark) || 0
    const end = endMark ? (this.marks.get(endMark) || performance.now()) : performance.now()
    const duration = end - start
    
    // Log slow operations
    if (duration > 100) {
      console.warn(`Slow operation detected: ${name} took ${duration}ms`)
    }
    
    // Report to monitoring
    metrics.histogram('operation_duration', duration, { operation: name })
    
    return duration
  }
  
  // Memory profiling
  static logMemoryUsage(context: string): void {
    if (global.gc) {
      global.gc() // Force GC if exposed
    }
    
    const usage = process.memoryUsage()
    metrics.gauge('memory_usage', usage.heapUsed, { 
      context,
      type: 'heap_used'
    })
    metrics.gauge('memory_usage', usage.external, {
      context,
      type: 'external'
    })
  }
}

// Automatic profiling decorator
export function profile(target: any, propertyName: string, descriptor: PropertyDescriptor) {
  const method = descriptor.value
  
  descriptor.value = async function(...args: any[]) {
    const start = performance.now()
    
    try {
      const result = await method.apply(this, args)
      
      const duration = performance.now() - start
      metrics.histogram('method_duration', duration, {
        class: target.constructor.name,
        method: propertyName
      })
      
      return result
    } catch (error) {
      metrics.counter('method_error', 1, {
        class: target.constructor.name,
        method: propertyName
      })
      throw error
    }
  }
  
  return descriptor
}
```

## Performance Best Practices

- [ ] Memoize expensive pure function calculations
- [ ] Use lazy evaluation for potentially unused computations
- [ ] Leverage structural sharing for immutable updates
- [ ] Implement appropriate caching strategies
- [ ] Use connection pooling for external resources
- [ ] Batch operations when possible
- [ ] Choose efficient data structures for use case
- [ ] Stream large datasets instead of loading into memory
- [ ] Monitor performance metrics in production
- [ ] Profile regularly to identify bottlenecks
- [ ] Optimize at architecture level before micro-optimizations