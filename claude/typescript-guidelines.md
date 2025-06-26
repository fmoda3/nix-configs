# TypeScript Guidelines

## Core Principles

All TypeScript code must follow the [Functional Core, Imperative Shell](./fcis-architecture.md) architecture with strong typing and functional patterns.

## Type Modeling

### Discriminated Unions for Sum Types

Always use discriminated unions to model finite states:

```typescript
type AuthState =
  | { kind: "anonymous" }
  | { kind: "authenticating" }
  | { kind: "authenticated"; user: User; token: Token }
  | { kind: "failed"; error: AuthError; attempts: number }

// Exhaustive pattern matching
function renderAuth(state: AuthState): ReactElement {
  switch (state.kind) {
    case "anonymous":
      return <LoginForm />
    case "authenticating":
      return <Spinner />
    case "authenticated":
      return <Dashboard user={state.user} />
    case "failed":
      return <ErrorMessage error={state.error} retry={state.attempts < 3} />
  }
}
```

### Branded Types for Type Safety

Prevent primitive type confusion:

```typescript
type UserId = string & { readonly _brand: "UserId" }
type Email = string & { readonly _brand: "Email" }

// Smart constructors
function UserId(value: string): UserId {
  if (!isValidUUID(value)) throw new Error("Invalid UUID")
  return value as UserId
}

function Email(value: string): Email {
  if (!value.includes("@")) throw new Error("Invalid email")
  return value as Email
}
```

### Template Literal Types

Use template literals for precise string types:

```typescript
type HTTPMethod = "GET" | "POST" | "PUT" | "DELETE" | "PATCH"
type APIPath = `/api/${string}`
type EventName = `on${Capitalize<string>}`

type Route<M extends HTTPMethod = HTTPMethod> = {
  method: M
  path: APIPath
  handler: RouteHandler<M>
}
```

## Functional Patterns

### Result and Option Types

Implement Result and Option for explicit error handling:

```typescript
type Result<T, E> = 
  | { kind: "ok"; value: T }
  | { kind: "err"; error: E }

type Option<T> = 
  | { kind: "some"; value: T }
  | { kind: "none" }

// Helper functions
const ok = <T>(value: T): Result<T, never> => ({ kind: "ok", value })
const err = <E>(error: E): Result<never, E> => ({ kind: "err", error })
const some = <T>(value: T): Option<T> => ({ kind: "some", value })
const none: Option<never> = { kind: "none" }

// Combinators
function map<T, U, E>(
  result: Result<T, E>, 
  fn: (value: T) => U
): Result<U, E> {
  return result.kind === "ok" 
    ? ok(fn(result.value))
    : result
}

function flatMap<T, U, E>(
  result: Result<T, E>,
  fn: (value: T) => Result<U, E>
): Result<U, E> {
  return result.kind === "ok"
    ? fn(result.value)
    : result
}
```

### Pipe Function for Composition

Create readable transformation pipelines:

```typescript
type PipeFunction = {
  <A>(a: A): A
  <A, B>(a: A, ab: (a: A) => B): B
  <A, B, C>(a: A, ab: (a: A) => B, bc: (b: B) => C): C
  <A, B, C, D>(a: A, ab: (a: A) => B, bc: (b: B) => C, cd: (c: C) => D): D
  // ... more overloads
}

const pipe: PipeFunction = (value: any, ...fns: Function[]) =>
  fns.reduce((acc, fn) => fn(acc), value)

// Usage
const processUser = (input: unknown) =>
  pipe(
    input,
    parseUserInput,
    validateUser,
    enrichUser,
    saveUser
  )
```

### Immutable Updates

Use spread operator and utility functions:

```typescript
// Records
const updateUser = (user: User, updates: Partial<User>): User => ({
  ...user,
  ...updates,
  updatedAt: new Date()
})

// Arrays
const addItem = <T>(items: readonly T[], item: T): readonly T[] => 
  [...items, item]

const removeItem = <T>(items: readonly T[], index: number): readonly T[] =>
  [...items.slice(0, index), ...items.slice(index + 1)]

const updateItem = <T>(
  items: readonly T[], 
  index: number, 
  update: (item: T) => T
): readonly T[] =>
  items.map((item, i) => i === index ? update(item) : item)
```

## Imperative Shell Patterns

### Dependency Injection with Context

```typescript
type Dependencies = {
  userRepo: UserRepository
  emailService: EmailService
  logger: Logger
}

type Context = {
  deps: Dependencies
  requestId: string
  userId?: UserId
}

// Shell function with dependencies
async function createUserHandler(
  ctx: Context,
  request: CreateUserRequest
): Promise<Result<User, UserError>> {
  const { deps: { userRepo, emailService, logger } } = ctx
  
  // Imperative: Check existence
  const exists = await userRepo.existsByEmail(request.email)
  if (exists) {
    return err({ kind: "EmailAlreadyExists" })
  }
  
  // Functional: Create user
  const userResult = createUser(request)
  if (userResult.kind === "err") {
    return userResult
  }
  
  // Imperative: Save and notify
  const user = userResult.value
  await userRepo.save(user)
  await emailService.sendWelcome(user.email)
  logger.info("User created", { userId: user.id, requestId: ctx.requestId })
  
  return ok(user)
}
```

### React Hooks for State Management

Keep effects in custom hooks, logic in pure functions:

```typescript
// Pure state reducer
type Action =
  | { type: "FETCH_START" }
  | { type: "FETCH_SUCCESS"; data: User[] }
  | { type: "FETCH_ERROR"; error: Error }
  | { type: "DELETE_USER"; userId: UserId }

function userReducer(state: UserState, action: Action): UserState {
  switch (action.type) {
    case "FETCH_START":
      return { ...state, loading: true, error: null }
    case "FETCH_SUCCESS":
      return { ...state, loading: false, users: action.data }
    case "FETCH_ERROR":
      return { ...state, loading: false, error: action.error }
    case "DELETE_USER":
      return {
        ...state,
        users: state.users.filter(u => u.id !== action.userId)
      }
  }
}

// Imperative hook
function useUsers() {
  const [state, dispatch] = useReducer(userReducer, initialState)
  
  const fetchUsers = useCallback(async () => {
    dispatch({ type: "FETCH_START" })
    try {
      const users = await api.getUsers()
      dispatch({ type: "FETCH_SUCCESS", data: users })
    } catch (error) {
      dispatch({ type: "FETCH_ERROR", error })
    }
  }, [])
  
  useEffect(() => {
    fetchUsers()
  }, [fetchUsers])
  
  return { ...state, refetch: fetchUsers }
}
```

## Type Guards and Predicates

### User-Defined Type Guards

```typescript
function isUser(value: unknown): value is User {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    "email" in value &&
    typeof value.id === "string" &&
    typeof value.email === "string"
  )
}

// Type predicate functions
const isNotNull = <T>(value: T | null): value is T => value !== null
const isDefined = <T>(value: T | undefined): value is T => value !== undefined
const hasValue = <T>(value: T | null | undefined): value is T => 
  value !== null && value !== undefined
```

### Exhaustiveness Checking

```typescript
function assertNever(x: never): never {
  throw new Error(`Unexpected value: ${x}`)
}

function processMessage(msg: Message) {
  switch (msg.type) {
    case "text":
      return processText(msg.content)
    case "image":
      return processImage(msg.url)
    case "video":
      return processVideo(msg.url, msg.duration)
    default:
      // TypeScript error if we miss a case
      return assertNever(msg)
  }
}
```

## Error Handling

### Custom Error Types

```typescript
abstract class AppError extends Error {
  abstract readonly kind: string
  abstract readonly statusCode: number
}

class ValidationError extends AppError {
  readonly kind = "ValidationError"
  readonly statusCode = 400
  constructor(public readonly errors: Record<string, string[]>) {
    super("Validation failed")
  }
}

class NotFoundError extends AppError {
  readonly kind = "NotFoundError"
  readonly statusCode = 404
  constructor(resource: string, id: string) {
    super(`${resource} with id ${id} not found`)
  }
}
```

### Try-Catch Wrapper

```typescript
async function tryCatch<T, E = Error>(
  fn: () => Promise<T>,
  onError: (error: unknown) => E
): Promise<Result<T, E>> {
  try {
    const value = await fn()
    return ok(value)
  } catch (error) {
    return err(onError(error))
  }
}

// Usage
const userResult = await tryCatch(
  () => fetchUser(userId),
  (error) => new NotFoundError("User", userId)
)
```

## Testing Patterns

### Type-Safe Test Factories

```typescript
const createUser = (overrides: Partial<User> = {}): User => ({
  id: UserId("test-id"),
  email: Email("test@example.com"),
  profile: createProfile(),
  createdAt: new Date("2024-01-01"),
  ...overrides
})

const createProfile = (overrides: Partial<Profile> = {}): Profile => ({
  displayName: "Test User",
  timezone: "UTC",
  preferences: defaultPreferences(),
  ...overrides
})
```

### Property Testing with fast-check

```typescript
import * as fc from 'fast-check'

describe('User validation', () => {
  it('should accept valid emails', () => {
    fc.assert(
      fc.property(
        fc.emailAddress(),
        (email) => {
          const result = validateEmail(email)
          return result.kind === "ok"
        }
      )
    )
  })
  
  it('should maintain invariants through transformations', () => {
    fc.assert(
      fc.property(
        fc.record({
          name: fc.string(),
          age: fc.integer({ min: 0, max: 150 })
        }),
        (userData) => {
          const user = createUser(userData)
          const serialized = JSON.stringify(user)
          const deserialized = JSON.parse(serialized)
          return deepEqual(user, deserialized)
        }
      )
    )
  })
})
```

## Module Organization

### Barrel Exports

Organize exports for clean imports:

```typescript
// models/index.ts
export * from './user'
export * from './order'
export * from './payment'

// utils/index.ts
export * from './result'
export * from './option'
export * from './pipe'

// Don't barrel export implementation details
```

### Module Boundaries

```typescript
// core/user/types.ts - Pure types
export type User = {
  readonly id: UserId
  readonly email: Email
  readonly profile: Profile
}

// core/user/logic.ts - Pure functions
export const createUser = (input: CreateUserInput): Result<User, ValidationError> => {
  // Pure validation and construction
}

// shell/user/repository.ts - Imperative
export interface UserRepository {
  findById(id: UserId): Promise<Option<User>>
  save(user: User): Promise<void>
}

// shell/user/service.ts - Orchestration
export class UserService {
  constructor(private repo: UserRepository) {}
  
  async createUser(input: CreateUserInput): Promise<Result<User, UserError>> {
    // Orchestrate between core and I/O
  }
}
```

## Performance

### Lazy Evaluation with Generators

```typescript
function* map<T, U>(items: Iterable<T>, fn: (item: T) => U): Generator<U> {
  for (const item of items) {
    yield fn(item)
  }
}

function* filter<T>(items: Iterable<T>, predicate: (item: T) => boolean): Generator<T> {
  for (const item of items) {
    if (predicate(item)) yield item
  }
}

// Compose lazy operations
const processLargeDataset = (data: Iterable<RawData>) =>
  pipe(
    data,
    (items) => filter(items, isValid),
    (items) => map(items, normalize),
    (items) => take(items, 1000)
  )
```

## Code Style

### Prefer `type` over `interface`

```typescript
// Prefer
type User = {
  id: string
  email: string
}

// Avoid (unless needed for extension)
interface IUser {
  id: string
  email: string
}
```

### Const Assertions

```typescript
// Use 'as const' for literal types
const colors = ["red", "green", "blue"] as const
type Color = typeof colors[number] // "red" | "green" | "blue"

const config = {
  api: {
    timeout: 5000,
    retries: 3
  }
} as const
```

### Avoid Enums

Prefer union types over enums:

```typescript
// Prefer
type Status = "pending" | "active" | "completed"

// Avoid
enum Status {
  Pending = "pending",
  Active = "active",
  Completed = "completed"
}
```