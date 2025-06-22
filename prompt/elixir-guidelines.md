# Elixir Guidelines

## Core Principles

All Elixir code must follow the [Functional Core, Imperative Shell](./fcis-architecture.md) architecture, adapting OTP patterns to maintain clear boundaries between pure logic and effects.

## Data Modeling

### Structs for Domain Types

Define explicit structs for all domain concepts:

```elixir
defmodule Core.User do
  @enforce_keys [:id, :email]
  defstruct [:id, :email, :profile, :created_at]
  
  @type t :: %__MODULE__{
    id: UserId.t(),
    email: Email.t(),
    profile: Profile.t() | nil,
    created_at: DateTime.t()
  }
end

defmodule Core.UserId do
  @opaque t :: %__MODULE__{value: binary()}
  defstruct [:value]
  
  def new(value) when is_binary(value) do
    {:ok, %__MODULE__{value: value}}
  end
  def new(_), do: {:error, :invalid_user_id}
end
```

### Tagged Tuples for Sum Types

Model states and results with consistent tagging:

```elixir
@type payment_state ::
  {:pending, pending_data :: map()}
  | {:processing, transaction_id :: String.t()}
  | {:completed, transaction_id :: String.t(), receipt :: Receipt.t()}
  | {:failed, error :: payment_error()}

@type payment_error ::
  {:insufficient_funds, available :: Money.t(), required :: Money.t()}
  | {:invalid_card, reason :: String.t()}
  | :card_expired
  | {:network_error, Exception.t()}
```

### Result Types

Standardize on consistent result types:

```elixir
@type result(t, e) :: {:ok, t} | {:error, e}
@type validation_result(t) :: {:ok, t} | {:error, [validation_error()]}

# Multi-error accumulation
defmodule Core.Validation do
  def validate_all(value, validators) do
    validators
    |> Enum.reduce({:ok, value, []}, fn validator, acc ->
      case acc do
        {:ok, val, errors} ->
          case validator.(val) do
            {:ok, new_val} -> {:ok, new_val, errors}
            {:error, err} -> {:ok, val, [err | errors]}
          end
        {:error, _} = error -> error
      end
    end)
    |> case do
      {:ok, val, []} -> {:ok, val}
      {:ok, _, errors} -> {:error, Enum.reverse(errors)}
    end
  end
end
```

## Functional Core Patterns

### Pure Transformation Pipelines

Keep business logic in pure functions:

```elixir
defmodule Core.Order do
  def process_order(order_request) do
    with {:ok, validated} <- validate_order(order_request),
         {:ok, priced} <- calculate_pricing(validated),
         {:ok, discounted} <- apply_discounts(priced),
         {:ok, finalized} <- finalize_order(discounted) do
      {:ok, finalized}
    end
  end
  
  defp validate_order(request) do
    request
    |> validate_items()
    |> validate_shipping()
    |> validate_payment_method()
    |> case do
      %{errors: []} = validated -> {:ok, validated}
      %{errors: errors} -> {:error, errors}
    end
  end
  
  # All helper functions are pure
  defp calculate_pricing(order) do
    # Pure calculation, no side effects
  end
end
```

### State Machine Modeling

Model state transitions explicitly:

```elixir
defmodule Core.OrderStateMachine do
  @type state :: :draft | :submitted | :processing | :shipped | :delivered | :cancelled
  @type event :: {:submit} | {:process} | {:ship, tracking_id :: String.t()} | {:deliver} | {:cancel, reason :: String.t()}
  
  @spec transition(state(), event()) :: {:ok, state()} | {:error, :invalid_transition}
  def transition(state, event) do
    case {state, event} do
      {:draft, {:submit}} -> {:ok, :submitted}
      {:submitted, {:process}} -> {:ok, :processing}
      {:processing, {:ship, _tracking}} -> {:ok, :shipped}
      {:shipped, {:deliver}} -> {:ok, :delivered}
      {state, {:cancel, _reason}} when state in [:draft, :submitted] -> {:ok, :cancelled}
      _ -> {:error, :invalid_transition}
    end
  end
  
  @spec available_events(state()) :: [event()]
  def available_events(state) do
    case state do
      :draft -> [{:submit}, {:cancel, "User cancelled"}]
      :submitted -> [{:process}, {:cancel, "User cancelled"}]
      :processing -> [{:ship, "TRACK123"}]
      :shipped -> [{:deliver}]
      _ -> []
    end
  end
end
```

### Functional Composition

Use function composition for complex transformations:

```elixir
defmodule Core.Pipeline do
  def compose(functions) do
    fn initial_value ->
      Enum.reduce(functions, {:ok, initial_value}, fn
        _fun, {:error, _} = error -> error
        fun, {:ok, value} -> fun.(value)
      end)
    end
  end
  
  # Usage
  def process_user_data(raw_data) do
    pipeline = compose([
      &parse_json/1,
      &validate_schema/1,
      &normalize_fields/1,
      &enrich_data/1
    ])
    
    pipeline.(raw_data)
  end
end
```

## Imperative Shell Patterns

### GenServer for Stateful Shells

Keep GenServers thin, delegate to functional core:

```elixir
defmodule Shell.OrderServer do
  use GenServer
  alias Core.{Order, OrderStateMachine}
  
  # Client API
  def start_link(order_id) do
    GenServer.start_link(__MODULE__, order_id, name: via_tuple(order_id))
  end
  
  def process_event(order_id, event) do
    GenServer.call(via_tuple(order_id), {:process_event, event})
  end
  
  # Server callbacks
  @impl true
  def init(order_id) do
    # Imperative: Load from database
    case OrderRepo.get(order_id) do
      {:ok, order} -> {:ok, order}
      {:error, reason} -> {:stop, reason}
    end
  end
  
  @impl true
  def handle_call({:process_event, event}, _from, order) do
    # Functional: Process state transition
    case OrderStateMachine.transition(order.state, event) do
      {:ok, new_state} ->
        # Imperative: Save and notify
        updated_order = %{order | state: new_state}
        :ok = OrderRepo.save(updated_order)
        :ok = EventBus.broadcast({:order_updated, updated_order})
        {:reply, {:ok, updated_order}, updated_order}
      
      {:error, reason} ->
        {:reply, {:error, reason}, order}
    end
  end
  
  defp via_tuple(order_id) do
    {:via, Registry, {OrderRegistry, order_id}}
  end
end
```

### Ecto in the Shell

Keep database operations at the boundary:

```elixir
defmodule Shell.UserService do
  alias Core.User
  alias Shell.{Repo, UserSchema}
  
  def create_user(params) do
    # Functional: Validate and create domain model
    with {:ok, user} <- User.create(params),
         # Imperative: Check uniqueness
         :ok <- ensure_email_unique(user.email),
         # Imperative: Save to database
         {:ok, _} <- insert_user(user),
         # Imperative: Send notifications
         :ok <- Mailer.send_welcome_email(user.email) do
      {:ok, user}
    end
  end
  
  defp ensure_email_unique(email) do
    case Repo.get_by(UserSchema, email: email) do
      nil -> :ok
      _ -> {:error, :email_taken}
    end
  end
  
  defp insert_user(user) do
    %UserSchema{}
    |> UserSchema.changeset(Map.from_struct(user))
    |> Repo.insert()
    |> case do
      {:ok, schema} -> {:ok, to_domain(schema)}
      {:error, changeset} -> {:error, changeset_errors(changeset)}
    end
  end
  
  defp to_domain(%UserSchema{} = schema) do
    {:ok, %User{
      id: schema.id,
      email: schema.email,
      profile: decode_profile(schema.profile)
    }}
  end
end
```

### Supervisors and Application Structure

Organize supervision trees to separate concerns:

```elixir
defmodule MyApp.Application do
  use Application
  
  def start(_type, _args) do
    children = [
      # Infrastructure (Shell)
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Endpoint,
      
      # Domain Supervisors (Shell managing Core)
      {Registry, keys: :unique, name: MyApp.OrderRegistry},
      MyApp.OrderSupervisor,
      MyApp.PaymentSupervisor,
      
      # Background Jobs (Shell)
      MyApp.JobQueue,
      MyApp.EmailWorker
    ]
    
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule MyApp.OrderSupervisor do
  use DynamicSupervisor
  
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  def start_order(order_id) do
    spec = {Shell.OrderServer, order_id}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
  
  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
```

## Testing Patterns

### Property-Based Testing

Use StreamData for property testing:

```elixir
defmodule Core.UserTest do
  use ExUnit.Case
  use ExUnitProperties
  
  property "email validation accepts valid emails" do
    check all email <- valid_email() do
      assert {:ok, _} = Email.new(email)
    end
  end
  
  property "state transitions maintain invariants" do
    check all state <- order_state(),
              event <- order_event() do
      case OrderStateMachine.transition(state, event) do
        {:ok, new_state} ->
          assert valid_state?(new_state)
          assert valid_transition?(state, event, new_state)
        
        {:error, :invalid_transition} ->
          assert not allowed_transition?(state, event)
      end
    end
  end
  
  def valid_email() do
    gen all local <- string(:alphanumeric, min_length: 1),
            domain <- string(:alphanumeric, min_length: 1),
            tld <- member_of(["com", "org", "net"]) do
      "#{local}@#{domain}.#{tld}"
    end
  end
end
```

### Mox for Shell Testing

Mock external dependencies in shell tests:

```elixir
# Define behaviour
defmodule MyApp.EmailService do
  @callback send_welcome(Email.t()) :: :ok | {:error, term()}
end

# Create mock
Mox.defmock(MyApp.EmailServiceMock, for: MyApp.EmailService)

# Test shell with mock
defmodule Shell.UserServiceTest do
  use MyApp.DataCase
  import Mox
  
  setup :verify_on_exit!
  
  test "create_user sends welcome email" do
    expect(MyApp.EmailServiceMock, :send_welcome, fn email ->
      assert email == "test@example.com"
      :ok
    end)
    
    params = %{email: "test@example.com", name: "Test User"}
    assert {:ok, user} = UserService.create_user(params)
    assert user.email == "test@example.com"
  end
end
```

### Test Factories

Create factories for test data:

```elixir
defmodule MyApp.Factory do
  alias Core.{User, Order, Product}
  
  def build(:user) do
    %User{
      id: UUID.uuid4(),
      email: sequence(:email, &"user#{&1}@example.com"),
      profile: build(:profile)
    }
  end
  
  def build(:order) do
    %Order{
      id: UUID.uuid4(),
      user_id: UUID.uuid4(),
      items: build_list(3, :order_item),
      state: :draft
    }
  end
  
  def build(factory, attrs) do
    factory
    |> build()
    |> struct!(attrs)
  end
  
  def build_list(count, factory) do
    Enum.map(1..count, fn _ -> build(factory) end)
  end
  
  defp sequence(name, formatter) do
    Agent.get_and_update(
      FactorySequence,
      fn sequences ->
        current = Map.get(sequences, name, 0)
        next = current + 1
        {formatter.(next), Map.put(sequences, name, next)}
      end
    )
  end
end
```

## Error Handling

### Structured Errors

Define error types with clear information:

```elixir
defmodule Core.Errors do
  defmodule ValidationError do
    defstruct [:field, :message, :code]
    
    @type t :: %__MODULE__{
      field: atom(),
      message: String.t(),
      code: atom()
    }
  end
  
  defmodule BusinessError do
    defstruct [:code, :message, :context]
    
    @type t :: %__MODULE__{
      code: atom(),
      message: String.t(),
      context: map()
    }
  end
  
  def insufficient_funds(available, required) do
    %BusinessError{
      code: :insufficient_funds,
      message: "Insufficient funds for transaction",
      context: %{available: available, required: required}
    }
  end
end
```

### Error Pipeline

Chain operations with consistent error handling:

```elixir
defmodule Core.Pipeline do
  defmacro pipe_with(value, pipes) do
    Enum.reduce(pipes, value, fn pipe, acc ->
      quote do
        case unquote(acc) do
          {:ok, val} -> unquote(pipe).(val)
          {:error, _} = error -> error
        end
      end
    end)
  end
  
  # Usage
  def process_payment(request) do
    pipe_with {:ok, request},
      [&validate_payment/1,
       &check_funds/1,
       &authorize_payment/1,
       &capture_payment/1]
  end
end
```

## Performance Patterns

### Stream Processing

Use streams for large data sets:

```elixir
defmodule Core.DataProcessor do
  def process_large_file(file_path) do
    file_path
    |> File.stream!()
    |> Stream.map(&parse_line/1)
    |> Stream.filter(&valid?/1)
    |> Stream.map(&transform/1)
    |> Stream.chunk_every(1000)
    |> Stream.each(&batch_process/1)
    |> Stream.run()
  end
  
  defp parse_line(line) do
    # Pure parsing logic
  end
  
  defp valid?(data) do
    # Pure validation
  end
  
  defp transform(data) do
    # Pure transformation
  end
  
  defp batch_process(batch) do
    # This is in the shell - can do I/O
    Repo.insert_all(Schema, batch)
  end
end
```

### ETS for Read-Heavy Caching

Use ETS in the shell for performance:

```elixir
defmodule Shell.Cache do
  use GenServer
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def get(key) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, value}] -> {:ok, value}
      [] -> {:error, :not_found}
    end
  end
  
  def put(key, value, ttl \\ :infinity) do
    GenServer.cast(__MODULE__, {:put, key, value, ttl})
  end
  
  @impl true
  def init(_opts) do
    :ets.new(__MODULE__, [:named_table, :public, read_concurrency: true])
    {:ok, %{}}
  end
  
  @impl true
  def handle_cast({:put, key, value, ttl}, state) do
    :ets.insert(__MODULE__, {key, value})
    if ttl != :infinity do
      Process.send_after(self(), {:expire, key}, ttl)
    end
    {:noreply, state}
  end
  
  @impl true
  def handle_info({:expire, key}, state) do
    :ets.delete(__MODULE__, key)
    {:noreply, state}
  end
end
```

## Code Style

### Module Organization

```elixir
defmodule MyApp.Core.User do
  @moduledoc """
  User domain logic and data structures.
  
  This module contains pure functions only.
  """
  
  # Type definitions first
  @type t :: %__MODULE__{
    id: binary(),
    email: String.t(),
    profile: Profile.t()
  }
  
  # Struct definition
  @enforce_keys [:id, :email]
  defstruct [:id, :email, :profile]
  
  # Public API functions
  def new(params) do
    # Implementation
  end
  
  def update(user, params) do
    # Implementation
  end
  
  # Private functions last
  defp validate_email(email) do
    # Implementation
  end
end
```

### Naming Conventions

- Use `?` suffix for boolean functions: `valid?/1`, `empty?/1`
- Use `!` suffix for functions that raise: `fetch!/2`
- Use descriptive names over abbreviations
- Prefer `do_action` over `action_impl` for private implementations

### Documentation

```elixir
@doc """
Creates a new user with the given parameters.

## Parameters

  * `params` - Map containing:
    * `:email` - User's email address (required)
    * `:name` - User's display name (optional)
    * `:profile` - Profile settings (optional)

## Returns

  * `{:ok, %User{}}` - Successfully created user
  * `{:error, errors}` - Validation errors

## Examples

      iex> User.create(%{email: "test@example.com"})
      {:ok, %User{email: "test@example.com"}}
      
      iex> User.create(%{})
      {:error, [email: "is required"]}
"""
@spec create(map()) :: {:ok, t()} | {:error, [validation_error()]}
def create(params) do
  # Implementation
end
```