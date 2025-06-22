# Security Patterns

## Core Principles

Security in a Functional Core, Imperative Shell architecture means keeping security logic pure and testable in the core while implementing security controls at the shell boundaries. Never trust external input, validate everything at the edge, and use type safety to prevent security issues.

## Input Validation and Sanitization

### Parse, Don't Validate for Security

```kotlin
// Secure parsing into domain types
sealed class SecureEmail {
    data class Valid(val value: String) : SecureEmail()
    data class Invalid(val reason: SecurityError) : SecureEmail()
    
    companion object {
        private val EMAIL_PATTERN = """^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$""".toRegex()
        private const val MAX_LENGTH = 254
        
        fun parse(input: String): SecureEmail {
            return when {
                input.length > MAX_LENGTH -> 
                    Invalid(SecurityError.InputTooLong("email", MAX_LENGTH))
                
                !EMAIL_PATTERN.matches(input) -> 
                    Invalid(SecurityError.InvalidFormat("email"))
                
                containsSqlInjectionPatterns(input) -> 
                    Invalid(SecurityError.MaliciousInput("email"))
                
                else -> Valid(input.lowercase())
            }
        }
        
        private fun containsSqlInjectionPatterns(input: String): Boolean {
            val dangerous = listOf("'--", "/*", "*/", "xp_", "sp_", "0x")
            return dangerous.any { input.contains(it, ignoreCase = true) }
        }
    }
}

// Secure string sanitization
object SecureSanitizer {
    fun sanitizeHtml(input: String): String {
        return input
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#x27;")
            .replace("/", "&#x2F;")
    }
    
    fun sanitizeFileName(input: String): Result<SecureFileName, SecurityError> {
        val cleaned = input
            .replace(Regex("[^a-zA-Z0-9._-]"), "_")
            .take(255)
        
        return when {
            cleaned.isEmpty() -> 
                Err(SecurityError.InvalidInput("Filename cannot be empty"))
            
            cleaned.startsWith(".") -> 
                Err(SecurityError.InvalidInput("Filename cannot start with ."))
            
            RESERVED_NAMES.contains(cleaned.uppercase()) ->
                Err(SecurityError.InvalidInput("Reserved filename"))
                
            else -> Ok(SecureFileName(cleaned))
        }
    }
    
    private val RESERVED_NAMES = setOf("CON", "PRN", "AUX", "NUL", "COM1", "LPT1")
}
```

### Type-Safe Query Building

```typescript
// Prevent SQL injection through type safety
export class SafeQueryBuilder {
  private params: any[] = []
  private paramCount = 0
  
  select(table: TableName, columns: ColumnName[]): this {
    this.query = `SELECT ${columns.join(', ')} FROM ${table}`
    return this
  }
  
  where(column: ColumnName, operator: SqlOperator, value: any): this {
    this.paramCount++
    this.query += ` WHERE ${column} ${operator} $${this.paramCount}`
    this.params.push(value)
    return this
  }
  
  build(): { query: string; params: any[] } {
    return { query: this.query, params: this.params }
  }
}

// Type-safe table and column names
type TableName = 'users' | 'orders' | 'products'
type ColumnName = 'id' | 'email' | 'status' | 'created_at'
type SqlOperator = '=' | '!=' | '>' | '<' | '>=' | '<=' | 'IN' | 'LIKE'

// Usage - SQL injection impossible
const query = new SafeQueryBuilder()
  .select('users', ['id', 'email'])
  .where('email', '=', userInput) // userInput is parameterized
  .build()
```

## Authentication and Authorization

### Token-Based Authentication

```elixir
defmodule Core.Auth.TokenValidator do
  @moduledoc """
  Pure token validation logic
  """
  
  @type token :: String.t()
  @type claims :: %{
    user_id: String.t(),
    email: String.t(),
    permissions: [String.t()],
    exp: integer()
  }
  
  @spec validate_token(token(), String.t()) :: {:ok, claims()} | {:error, auth_error()}
  def validate_token(token, secret) do
    with {:ok, jwt} <- parse_jwt(token),
         :ok <- verify_signature(jwt, secret),
         :ok <- check_expiration(jwt.claims),
         :ok <- validate_claims(jwt.claims) do
      {:ok, jwt.claims}
    end
  end
  
  defp verify_signature(jwt, secret) do
    expected = :crypto.mac(:hmac, :sha256, secret, jwt.payload)
    
    if Plug.Crypto.secure_compare(jwt.signature, expected) do
      :ok
    else
      {:error, :invalid_signature}
    end
  end
  
  defp check_expiration(%{exp: exp}) do
    if exp > System.system_time(:second) do
      :ok
    else
      {:error, :token_expired}
    end
  end
  
  defp validate_claims(claims) do
    required = [:user_id, :email, :permissions, :exp]
    
    if Enum.all?(required, &Map.has_key?(claims, &1)) do
      :ok
    else
      {:error, :missing_claims}
    end
  end
end

defmodule Shell.Auth.Middleware do
  @moduledoc """
  Authentication middleware in the shell
  """
  
  def authenticate(conn, _opts) do
    with {:ok, token} <- extract_token(conn),
         {:ok, claims} <- Core.Auth.TokenValidator.validate_token(token, secret()) do
      conn
      |> assign(:current_user, claims)
      |> assign(:permissions, claims.permissions)
    else
      {:error, reason} ->
        conn
        |> put_status(401)
        |> json(%{error: format_error(reason)})
        |> halt()
    end
  end
  
  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> {:error, :missing_token}
    end
  end
  
  defp secret do
    System.get_env("JWT_SECRET") || raise "JWT_SECRET not configured"
  end
end
```

### Fine-Grained Authorization

```kotlin
// Authorization rules in functional core
object AuthorizationRules {
    fun canViewOrder(user: AuthenticatedUser, order: Order): Boolean {
        return when {
            user.hasPermission(Permission.ADMIN) -> true
            user.id == order.customerId -> true
            user.hasPermission(Permission.SUPPORT) && order.status != OrderStatus.DRAFT -> true
            else -> false
        }
    }
    
    fun canModifyOrder(user: AuthenticatedUser, order: Order): Boolean {
        return when {
            user.hasPermission(Permission.ADMIN) -> true
            user.id == order.customerId && order.status == OrderStatus.DRAFT -> true
            else -> false
        }
    }
    
    fun canAccessResource(user: AuthenticatedUser, resource: Resource): Boolean {
        return when (resource) {
            is Resource.Public -> true
            
            is Resource.Private -> 
                user.id == resource.ownerId || user.hasPermission(Permission.ADMIN)
            
            is Resource.Restricted ->
                resource.allowedRoles.any { role -> user.hasRole(role) }
        }
    }
}

// Attribute-based access control (ABAC)
data class AccessContext(
    val subject: AuthenticatedUser,
    val action: Action,
    val resource: Resource,
    val environment: Environment
)

enum class Action {
    READ, WRITE, DELETE, EXECUTE
}

data class Environment(
    val ipAddress: String,
    val timestamp: Instant,
    val requestId: String
)

object ABACEngine {
    fun evaluate(context: AccessContext): AccessDecision {
        val applicable = PolicyStore.findApplicable(context)
        
        return when {
            applicable.any { it.effect == Effect.DENY && it.evaluate(context) } ->
                AccessDecision.Deny("Explicit deny policy")
            
            applicable.any { it.effect == Effect.ALLOW && it.evaluate(context) } ->
                AccessDecision.Allow
            
            else ->
                AccessDecision.Deny("No applicable allow policy")
        }
    }
}
```

## Cryptography

### Secure Password Handling

```typescript
import { randomBytes, scrypt, timingSafeEqual } from 'crypto'
import { promisify } from 'util'

const scryptAsync = promisify(scrypt)

export class PasswordHasher {
  private static readonly SALT_LENGTH = 32
  private static readonly KEY_LENGTH = 64
  private static readonly SCRYPT_COST = 16384
  private static readonly SCRYPT_BLOCK_SIZE = 8
  private static readonly SCRYPT_PARALLELIZATION = 1
  
  static async hash(password: string): Promise<string> {
    const salt = randomBytes(this.SALT_LENGTH)
    
    const hash = await scryptAsync(
      password,
      salt,
      this.KEY_LENGTH,
      {
        N: this.SCRYPT_COST,
        r: this.SCRYPT_BLOCK_SIZE,
        p: this.SCRYPT_PARALLELIZATION
      }
    ) as Buffer
    
    // Format: algorithm$cost$salt$hash
    return `scrypt$${this.SCRYPT_COST}$${salt.toString('base64')}$${hash.toString('base64')}`
  }
  
  static async verify(password: string, storedHash: string): Promise<boolean> {
    const [algorithm, cost, saltBase64, hashBase64] = storedHash.split('$')
    
    if (algorithm !== 'scrypt') {
      throw new Error('Unsupported algorithm')
    }
    
    const salt = Buffer.from(saltBase64, 'base64')
    const storedHashBuffer = Buffer.from(hashBase64, 'base64')
    
    const hash = await scryptAsync(
      password,
      salt,
      this.KEY_LENGTH,
      {
        N: parseInt(cost),
        r: this.SCRYPT_BLOCK_SIZE,
        p: this.SCRYPT_PARALLELIZATION
      }
    ) as Buffer
    
    return timingSafeEqual(hash, storedHashBuffer)
  }
}

// Secure random token generation
export class SecureTokenGenerator {
  static generate(length: number = 32): string {
    return randomBytes(length).toString('base64url')
  }
  
  static generateNumeric(length: number = 6): string {
    const bytes = randomBytes(length)
    let result = ''
    
    for (const byte of bytes) {
      result += (byte % 10).toString()
    }
    
    return result.slice(0, length)
  }
}
```

### Encryption at Rest

```elixir
defmodule Core.Crypto.DataEncryption do
  @moduledoc """
  Secure encryption for sensitive data
  """
  
  @aad "MyApp.Encryption.V1"
  
  def encrypt(plaintext, key) when is_binary(plaintext) and byte_size(key) == 32 do
    iv = :crypto.strong_rand_bytes(12)
    
    {ciphertext, tag} = :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      key,
      iv,
      plaintext,
      @aad,
      true
    )
    
    # Format: version(1) || iv(12) || tag(16) || ciphertext
    {:ok, <<1::8, iv::binary-12, tag::binary-16, ciphertext::binary>>}
  rescue
    _ -> {:error, :encryption_failed}
  end
  
  def decrypt(encrypted, key) when is_binary(encrypted) and byte_size(key) == 32 do
    case encrypted do
      <<1::8, iv::binary-12, tag::binary-16, ciphertext::binary>> ->
        case :crypto.crypto_one_time_aead(
          :aes_256_gcm,
          key,
          iv,
          ciphertext,
          @aad,
          tag,
          false
        ) do
          :error -> {:error, :decryption_failed}
          plaintext -> {:ok, plaintext}
        end
      
      _ ->
        {:error, :invalid_format}
    end
  end
  
  # Key derivation for field-level encryption
  def derive_field_key(master_key, field_name, record_id) do
    info = "#{field_name}:#{record_id}"
    
    :crypto.mac(:hmac, :sha256, master_key, info)
    |> binary_part(0, 32)
  end
end

defmodule Shell.Crypto.EncryptedField do
  @behaviour Ecto.Type
  
  def type, do: :binary
  
  def cast(value) when is_binary(value), do: {:ok, value}
  def cast(_), do: :error
  
  def dump(value) when is_binary(value) do
    case Core.Crypto.DataEncryption.encrypt(value, encryption_key()) do
      {:ok, encrypted} -> {:ok, encrypted}
      {:error, _} -> :error
    end
  end
  
  def load(encrypted) when is_binary(encrypted) do
    case Core.Crypto.DataEncryption.decrypt(encrypted, encryption_key()) do
      {:ok, decrypted} -> {:ok, decrypted}
      {:error, _} -> :error
    end
  end
  
  defp encryption_key do
    Application.get_env(:my_app, :encryption_key)
    |> Base.decode64!()
  end
end
```

## API Security

### Rate Limiting

```kotlin
// Token bucket rate limiter
class TokenBucketRateLimiter(
    private val capacity: Long,
    private val refillRate: Long,
    private val refillPeriod: Duration
) {
    private val buckets = ConcurrentHashMap<String, TokenBucket>()
    
    fun tryConsume(key: String, tokens: Long = 1): RateLimitResult {
        val bucket = buckets.computeIfAbsent(key) {
            TokenBucket(capacity, capacity, Instant.now())
        }
        
        return bucket.tryConsume(tokens, refillRate, refillPeriod)
    }
    
    data class TokenBucket(
        val capacity: Long,
        @Volatile var tokens: Long,
        @Volatile var lastRefill: Instant
    ) {
        fun tryConsume(requested: Long, refillRate: Long, refillPeriod: Duration): RateLimitResult {
            synchronized(this) {
                // Refill tokens
                val now = Instant.now()
                val elapsed = Duration.between(lastRefill, now)
                val periodsElapsed = elapsed.toMillis() / refillPeriod.toMillis()
                
                if (periodsElapsed > 0) {
                    val tokensToAdd = periodsElapsed * refillRate
                    tokens = min(capacity, tokens + tokensToAdd)
                    lastRefill = lastRefill.plus(refillPeriod.multipliedBy(periodsElapsed))
                }
                
                // Try to consume
                return if (tokens >= requested) {
                    tokens -= requested
                    RateLimitResult.Allowed(
                        remaining = tokens,
                        resetAt = lastRefill.plus(refillPeriod)
                    )
                } else {
                    RateLimitResult.Denied(
                        retryAfter = Duration.between(now, lastRefill.plus(refillPeriod))
                    )
                }
            }
        }
    }
}

sealed class RateLimitResult {
    data class Allowed(val remaining: Long, val resetAt: Instant) : RateLimitResult()
    data class Denied(val retryAfter: Duration) : RateLimitResult()
}
```

### CORS and CSP Headers

```typescript
// Security headers middleware
export function securityHeaders(options: SecurityOptions = {}): RequestHandler {
  const defaults: SecurityOptions = {
    contentSecurityPolicy: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'strict-dynamic'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'none'"],
      frameSrc: ["'none'"]
    },
    cors: {
      origin: process.env.ALLOWED_ORIGINS?.split(',') || ['https://app.example.com'],
      credentials: true,
      maxAge: 86400
    },
    frameOptions: 'DENY',
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true
    }
  }
  
  const config = { ...defaults, ...options }
  
  return (req: Request, res: Response, next: NextFunction) => {
    // Content Security Policy
    const csp = Object.entries(config.contentSecurityPolicy)
      .map(([key, values]) => `${key} ${values.join(' ')}`)
      .join('; ')
    res.setHeader('Content-Security-Policy', csp)
    
    // CORS
    const origin = req.headers.origin
    if (origin && config.cors.origin.includes(origin)) {
      res.setHeader('Access-Control-Allow-Origin', origin)
      res.setHeader('Access-Control-Allow-Credentials', 'true')
      res.setHeader('Access-Control-Max-Age', config.cors.maxAge.toString())
    }
    
    // Security headers
    res.setHeader('X-Frame-Options', config.frameOptions)
    res.setHeader('X-Content-Type-Options', 'nosniff')
    res.setHeader('X-XSS-Protection', '1; mode=block')
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin')
    
    // HSTS
    res.setHeader(
      'Strict-Transport-Security',
      `max-age=${config.hsts.maxAge}; includeSubDomains; preload`
    )
    
    next()
  }
}
```

## Session Security

### Secure Session Management

```elixir
defmodule Core.Session.Security do
  @session_timeout_minutes 30
  @max_concurrent_sessions 5
  
  defmodule Session do
    @type t :: %__MODULE__{
      id: String.t(),
      user_id: String.t(),
      created_at: DateTime.t(),
      last_active: DateTime.t(),
      ip_address: String.t(),
      user_agent: String.t(),
      metadata: map()
    }
    
    defstruct [:id, :user_id, :created_at, :last_active, :ip_address, :user_agent, metadata: %{}]
  end
  
  @spec create_session(String.t(), String.t(), String.t()) :: {:ok, Session.t()}
  def create_session(user_id, ip_address, user_agent) do
    session = %Session{
      id: generate_secure_id(),
      user_id: user_id,
      created_at: DateTime.utc_now(),
      last_active: DateTime.utc_now(),
      ip_address: hash_ip(ip_address),
      user_agent: hash_user_agent(user_agent)
    }
    
    {:ok, session}
  end
  
  @spec validate_session(Session.t(), String.t(), String.t()) :: 
    {:ok, Session.t()} | {:error, session_error()}
  def validate_session(session, current_ip, current_user_agent) do
    cond do
      session_expired?(session) ->
        {:error, :session_expired}
      
      !ip_matches?(session.ip_address, current_ip) ->
        {:error, :ip_mismatch}
      
      !user_agent_matches?(session.user_agent, current_user_agent) ->
        {:error, :user_agent_mismatch}
      
      true ->
        {:ok, %{session | last_active: DateTime.utc_now()}}
    end
  end
  
  defp session_expired?(session) do
    DateTime.diff(DateTime.utc_now(), session.last_active, :minute) > @session_timeout_minutes
  end
  
  defp generate_secure_id do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
  
  defp hash_ip(ip) do
    # Hash IP for privacy while maintaining consistency for security checks
    :crypto.hash(:sha256, ip <> Application.get_env(:my_app, :ip_salt))
    |> Base.encode16()
  end
  
  defp ip_matches?(hashed_ip, current_ip) do
    hash_ip(current_ip) == hashed_ip
  end
end

defmodule Shell.Session.Store do
  @behaviour Plug.Session.Store
  
  def init(opts) do
    Keyword.put_new(opts, :key_prefix, "session:")
  end
  
  def get(conn, cookie, opts) do
    case verify_cookie(cookie) do
      {:ok, session_id} ->
        case Redis.get(opts[:key_prefix] <> session_id) do
          {:ok, nil} -> {nil, %{}}
          {:ok, data} -> {cookie, deserialize(data)}
          {:error, _} -> {nil, %{}}
        end
      
      :error ->
        {nil, %{}}
    end
  end
  
  def put(conn, session_id, data, opts) do
    session_id = session_id || generate_session_id()
    key = opts[:key_prefix] <> session_id
    
    Redis.setex(key, 1800, serialize(data))
    sign_cookie(session_id)
  end
  
  def delete(conn, session_id, opts) do
    Redis.del(opts[:key_prefix] <> session_id)
    :ok
  end
  
  defp sign_cookie(session_id) do
    secret = Application.get_env(:my_app, :secret_key_base)
    Phoenix.Token.sign(MyAppWeb.Endpoint, "session", session_id)
  end
  
  defp verify_cookie(cookie) do
    secret = Application.get_env(:my_app, :secret_key_base)
    case Phoenix.Token.verify(MyAppWeb.Endpoint, "session", cookie, max_age: 1800) do
      {:ok, session_id} -> {:ok, session_id}
      _ -> :error
    end
  end
end
```

## Audit Logging

### Security Event Logging

```kotlin
// Immutable audit events
sealed class SecurityEvent {
    abstract val timestamp: Instant
    abstract val userId: String?
    abstract val ipAddress: String
    abstract val userAgent: String
    
    data class LoginAttempt(
        override val timestamp: Instant,
        override val userId: String?,
        override val ipAddress: String,
        override val userAgent: String,
        val success: Boolean,
        val failureReason: String?
    ) : SecurityEvent()
    
    data class PermissionCheck(
        override val timestamp: Instant,
        override val userId: String?,
        override val ipAddress: String,
        override val userAgent: String,
        val resource: String,
        val action: String,
        val granted: Boolean,
        val reason: String
    ) : SecurityEvent()
    
    data class DataAccess(
        override val timestamp: Instant,
        override val userId: String?,
        override val ipAddress: String,
        override val userAgent: String,
        val entityType: String,
        val entityId: String,
        val operation: String,
        val fields: List<String>
    ) : SecurityEvent()
    
    data class ConfigChange(
        override val timestamp: Instant,
        override val userId: String?,
        override val ipAddress: String,
        override val userAgent: String,
        val setting: String,
        val oldValue: String,
        val newValue: String
    ) : SecurityEvent()
}

// Secure audit logger
object SecurityAuditLogger {
    private val logger = LoggerFactory.getLogger("SECURITY_AUDIT")
    
    fun log(event: SecurityEvent) {
        val json = Json.encodeToString(event)
        val signature = signEvent(json)
        
        logger.info(
            """
            {
              "event": $json,
              "signature": "$signature",
              "version": "1.0"
            }
            """.trimIndent()
        )
    }
    
    private fun signEvent(eventJson: String): String {
        val key = getAuditSigningKey()
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(key, "HmacSHA256"))
        return Base64.getEncoder().encodeToString(mac.doFinal(eventJson.toByteArray()))
    }
    
    fun verifyEvent(eventJson: String, signature: String): Boolean {
        val expectedSignature = signEvent(eventJson)
        return MessageDigest.isEqual(
            signature.toByteArray(),
            expectedSignature.toByteArray()
        )
    }
}
```

## Data Privacy

### PII Handling

```typescript
// Type-safe PII handling
export interface PersonalData {
  readonly _brand: 'PersonalData'
}

export type PII<T> = T & PersonalData

// PII types
export type EmailPII = PII<string>
export type PhonePII = PII<string>
export type AddressPII = PII<{
  street: string
  city: string
  postalCode: string
  country: string
}>

// PII protection utilities
export class PIIProtection {
  static mask(value: string, visibleChars: number = 4): string {
    if (value.length <= visibleChars) {
      return '*'.repeat(value.length)
    }
    
    const visible = value.slice(0, visibleChars)
    const masked = '*'.repeat(value.length - visibleChars)
    return visible + masked
  }
  
  static maskEmail(email: EmailPII): string {
    const [local, domain] = email.split('@')
    return this.mask(local, 2) + '@' + domain
  }
  
  static redact<T extends Record<string, any>>(
    obj: T,
    piiFields: (keyof T)[]
  ): T {
    const redacted = { ...obj }
    
    for (const field of piiFields) {
      if (field in redacted) {
        redacted[field] = '[REDACTED]' as any
      }
    }
    
    return redacted
  }
  
  static anonymize<T>(data: T & PersonalData): string {
    // One-way hash for anonymization
    const hash = createHash('sha256')
    hash.update(JSON.stringify(data))
    hash.update(process.env.ANONYMIZATION_SALT!)
    return hash.digest('hex')
  }
}

// GDPR compliance helpers
export class GDPRCompliance {
  static exportUserData(user: User): UserDataExport {
    return {
      profile: {
        id: user.id,
        email: user.email,
        name: user.name,
        createdAt: user.createdAt
      },
      activity: {
        lastLogin: user.lastLogin,
        loginCount: user.loginCount
      },
      preferences: user.preferences,
      exportedAt: new Date().toISOString(),
      format: 'json'
    }
  }
  
  static anonymizeUser(user: User): AnonymizedUser {
    return {
      id: PIIProtection.anonymize(user.email),
      createdAt: user.createdAt,
      // Preserve non-PII data for analytics
      country: user.address?.country,
      userType: user.userType,
      // Remove all PII
      email: undefined,
      name: undefined,
      phone: undefined,
      address: undefined
    }
  }
}
```

## Security Testing

### Security Test Patterns

```elixir
defmodule SecurityTest do
  use ExUnit.Case
  
  describe "input validation" do
    test "rejects SQL injection attempts" do
      malicious_inputs = [
        "admin' OR '1'='1",
        "'; DROP TABLE users; --",
        "1' UNION SELECT * FROM passwords --",
        "admin'/*",
        "' OR 1=1#"
      ]
      
      for input <- malicious_inputs do
        assert {:error, _} = Core.Validation.validate_username(input)
      end
    end
    
    test "rejects XSS attempts" do
      xss_payloads = [
        "<script>alert('XSS')</script>",
        "<img src=x onerror=alert('XSS')>",
        "<svg onload=alert('XSS')>",
        "javascript:alert('XSS')",
        "<iframe src='javascript:alert()'>"
      ]
      
      for payload <- xss_payloads do
        result = Core.Sanitizer.sanitize_html(payload)
        refute result =~ "<script"
        refute result =~ "javascript:"
        refute result =~ "onerror"
        refute result =~ "onload"
      end
    end
    
    test "rate limiting prevents brute force" do
      # Simulate rapid requests
      results = for i <- 1..100 do
        Core.RateLimiter.check_rate("test-key", i)
      end
      
      # Should start blocking after threshold
      allowed = Enum.count(results, &match?({:ok, _}, &1))
      blocked = Enum.count(results, &match?({:error, :rate_limited}, &1))
      
      assert allowed <= 10
      assert blocked >= 90
    end
  end
  
  describe "cryptography" do
    test "password hashing is salted" do
      password = "TestPassword123!"
      hash1 = Core.Crypto.hash_password(password)
      hash2 = Core.Crypto.hash_password(password)
      
      # Same password should produce different hashes (salted)
      assert hash1 != hash2
      
      # But both should verify correctly
      assert Core.Crypto.verify_password(password, hash1)
      assert Core.Crypto.verify_password(password, hash2)
    end
    
    test "encryption produces different ciphertext for same plaintext" do
      plaintext = "Sensitive data"
      key = :crypto.strong_rand_bytes(32)
      
      {:ok, encrypted1} = Core.Crypto.encrypt(plaintext, key)
      {:ok, encrypted2} = Core.Crypto.encrypt(plaintext, key)
      
      # Different due to random IV
      assert encrypted1 != encrypted2
      
      # But both decrypt correctly
      assert {:ok, ^plaintext} = Core.Crypto.decrypt(encrypted1, key)
      assert {:ok, ^plaintext} = Core.Crypto.decrypt(encrypted2, key)
    end
  end
end
```

## Security Checklist

- [ ] All input is validated and sanitized at system boundaries
- [ ] Authentication tokens are securely generated and validated
- [ ] Authorization rules are implemented in the functional core
- [ ] Passwords are hashed with salt using strong algorithms
- [ ] Sensitive data is encrypted at rest and in transit
- [ ] API endpoints are rate-limited to prevent abuse
- [ ] Security headers are properly configured
- [ ] Sessions are managed securely with appropriate timeouts
- [ ] All security events are logged for audit trails
- [ ] PII is handled according to privacy regulations
- [ ] Regular security testing is performed
- [ ] Dependencies are kept up-to-date with security patches