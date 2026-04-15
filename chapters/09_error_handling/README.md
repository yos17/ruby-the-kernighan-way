# Chapter 9 — Error Handling

This chapter is important because beginner programs often work only on the happy path.

Real tools need to handle bad input, missing files, invalid data, and unexpected states.

Error handling is how the program stays honest when things go wrong.

## Exceptions Are Objects

In Ruby, exceptions are objects — instances of `Exception` or its subclasses. When something goes wrong, an exception is **raised** (thrown). You can **rescue** (catch) it and decide what to do.

```
Exception
└── StandardError        ← rescue this (most errors)
    ├── RuntimeError     ← raise "message" raises this
    ├── ArgumentError    ← wrong arguments
    ├── TypeError        ← wrong type
    ├── NameError        ← undefined variable/method
    │   └── NoMethodError
    ├── IndexError       ← array index out of bounds
    │   └── KeyError     ← missing hash key
    ├── IOError          ← file/IO problems
    │   └── Errno::ENOENT ← file not found
    ├── ZeroDivisionError
    ├── NotImplementedError
    └── StopIteration
```

Always rescue `StandardError` or a specific subclass — never bare `Exception` (that catches system signals too).

A good beginner rule is: rescue the most specific error you reasonably expect.

---

## raise and rescue

In plain English:
- `raise` means “something went wrong, stop normal flow here”
- `rescue` means “if that specific kind of problem happens, handle it this way instead”

```ruby
# raise an exception:
raise "Something went wrong"           # raises RuntimeError
raise ArgumentError, "Need a number"
raise ArgumentError.new("Need a number")  # same

# rescue:
begin
  result = 10 / 0
rescue ZeroDivisionError => e
  puts "Division error: #{e.message}"
  result = 0
end

# rescue multiple types:
begin
  data = File.read("config.json")
  JSON.parse(data)
rescue Errno::ENOENT => e
  puts "File not found: #{e.message}"
rescue JSON::ParserError => e
  puts "Invalid JSON: #{e.message}"
rescue => e                          # catches any StandardError
  puts "Unexpected error: #{e.message}"
ensure                               # ALWAYS runs (like finally)
  puts "Cleanup done"
end

# rescue in a method (no begin...end needed):
def load_config(path)
  JSON.parse(File.read(path))
rescue Errno::ENOENT
  {}    # return empty hash if file missing
rescue JSON::ParserError => e
  raise ArgumentError, "Invalid config file: #{e.message}"
end
```

---

## retry — Try Again

```ruby
attempts = 0
begin
  attempts += 1
  result = unstable_network_call()
rescue NetworkError => e
  retry if attempts < 3
  raise "Failed after 3 attempts: #{e.message}"
end

# Cleaner with a helper:
def with_retry(times:, &block)
  attempts = 0
  begin
    attempts += 1
    block.call
  rescue => e
    retry if attempts < times
    raise "Failed after #{times} attempts: #{e.message}"
  end
end

with_retry(times: 3) { fetch_data_from_api }
```

---

## Custom Exceptions

```ruby
# Define your own:
class InsufficientFundsError < StandardError
  attr_reader :amount, :balance

  def initialize(amount, balance)
    @amount  = amount
    @balance = balance
    super("Cannot withdraw $#{amount}. Balance: $#{balance}")
  end
end

class AccountFrozenError < StandardError; end

class BankAccount
  def withdraw(amount)
    raise AccountFrozenError if @frozen
    raise InsufficientFundsError.new(amount, @balance) if amount > @balance
    @balance -= amount
  end
end

# Caller can handle specifically:
begin
  account.withdraw(1000)
rescue InsufficientFundsError => e
  puts "Short by $#{e.amount - e.balance}"
rescue AccountFrozenError
  puts "Account is frozen"
end
```

---

## The ensure Block

```ruby
def process_file(path)
  file = File.open(path)
  # ... process
  file.read
ensure
  file&.close    # always close, even if exception raised
end
```

`ensure` always runs — whether an exception was raised or not. This is for cleanup: closing files, releasing connections, etc.

The block form (`File.open { |f| ... }`) handles this automatically, which is why it's preferred.

---

## Raise, Rescue, and Control Flow

```ruby
# rescue returns a value
result = begin
  Integer("not a number")
rescue ArgumentError
  0
end
result   # => 0

# One-line rescue (for simple cases)
value = Integer(str) rescue 0

# raise re-raises the current exception
def parse_config(data)
  JSON.parse(data)
rescue JSON::ParserError => e
  log_error(e)
  raise   # re-raise the same exception
end
```

---

## Your Program: A Robust File Parser

```ruby
# robust_parser.rb — parse a config file with full error handling

require 'json'

class ConfigError < StandardError; end
class MissingKeyError < ConfigError
  def initialize(key)
    super("Required key missing: '#{key}'")
  end
end

class Config
  REQUIRED_KEYS = %w[host port database]

  def initialize(path)
    @path = path
    @data = load_and_validate
  end

  def [](key)
    @data[key]
  end

  def to_s
    "Config(#{@data.map { |k,v| "#{k}: #{v}" }.join(', ')})"
  end

  private

  def load_and_validate
    raw = read_file
    parsed = parse_json(raw)
    validate(parsed)
    parsed
  end

  def read_file
    File.read(@path)
  rescue Errno::ENOENT
    raise ConfigError, "Config file not found: #{@path}"
  rescue Errno::EACCES
    raise ConfigError, "Cannot read config file: #{@path} (permission denied)"
  end

  def parse_json(raw)
    JSON.parse(raw)
  rescue JSON::ParserError => e
    raise ConfigError, "Invalid JSON in #{@path}: #{e.message}"
  end

  def validate(data)
    REQUIRED_KEYS.each do |key|
      raise MissingKeyError, key unless data.key?(key)
    end

    port = data["port"]
    unless port.is_a?(Integer) && port.between?(1, 65535)
      raise ConfigError, "Port must be an integer between 1 and 65535, got: #{port.inspect}"
    end
  end
end

# Usage
begin
  config = Config.new(ARGV[0] || "config.json")
  puts "Loaded config: #{config}"
  puts "Host: #{config["host"]}"
  puts "Port: #{config["port"]}"
rescue MissingKeyError => e
  puts "Config incomplete: #{e.message}"
  exit 1
rescue ConfigError => e
  puts "Config error: #{e.message}"
  exit 1
end
```

---

## Exercises

1. Write `safe_divide` that never raises, returns `nil` on division by zero.
2. Write `parse_date(str)` that tries multiple date formats (`%Y-%m-%d`, `%d/%m/%Y`, `%B %d, %Y`) and raises `ArgumentError` with all tried formats if none work.
3. Build `CircuitBreaker` — after N failures, stop trying and fail fast for M seconds.
4. Write a `Result` type (like Rust's `Ok`/`Err`) — `Result.ok(value)` and `Result.err(message)` — without using exceptions.

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| `raise` | throws an exception |
| `rescue` | catches exceptions |
| `ensure` | always runs (cleanup) |
| `retry` | re-run the begin block |
| Custom exceptions | `class MyError < StandardError` |
| Rescue hierarchy | catch `StandardError` or specific subclass |
| `rescue => e` | catches any `StandardError` |
| `rescue` in method | no `begin/end` needed at method level |
| One-line rescue | `value = expr rescue default` |

---

## Solutions

### Exercise 1

```ruby
# safe_divide — never raises, returns nil on division by zero

def safe_divide(a, b)
  return nil if b == 0
  a.to_f / b
end

# Or using inline rescue:
def safe_divide_v2(a, b)
  a.to_f / b rescue nil
end

safe_divide(10, 2)    # => 5.0
safe_divide(10, 0)    # => nil
safe_divide(7, 3)     # => 2.3333...

# Usage in context:
result = safe_divide(total, count)
average = result || 0.0
puts "Average: #{average}"
```

### Exercise 2

```ruby
# parse_date — try multiple formats, raise with details on failure

require 'date'

def parse_date(str)
  formats = ["%Y-%m-%d", "%d/%m/%Y", "%B %d, %Y", "%b %d, %Y", "%m/%d/%Y"]

  formats.each do |fmt|
    begin
      return Date.strptime(str, fmt)
    rescue Date::Error, ArgumentError
      next   # try the next format
    end
  end

  raise ArgumentError, "Cannot parse date '#{str}'. Tried formats: #{formats.join(', ')}"
end

parse_date("2026-01-15")        # => #<Date: 2026-01-15>
parse_date("15/01/2026")        # => #<Date: 2026-01-15>
parse_date("January 15, 2026")  # => #<Date: 2026-01-15>
parse_date("Jan 15, 2026")      # => #<Date: 2026-01-15>

begin
  parse_date("not a date")
rescue ArgumentError => e
  puts e.message
  # => Cannot parse date 'not a date'. Tried formats: %Y-%m-%d, %d/%m/%Y, ...
end
```

### Exercise 3

```ruby
# CircuitBreaker — fail fast after N failures for M seconds

class CircuitBreaker
  STATES = %i[closed open half_open].freeze

  def initialize(failure_threshold: 3, reset_timeout: 60)
    @failure_threshold = failure_threshold
    @reset_timeout     = reset_timeout
    @failure_count     = 0
    @state             = :closed
    @opened_at         = nil
  end

  def call(&block)
    case @state
    when :open
      if Time.now - @opened_at >= @reset_timeout
        @state = :half_open
        puts "Circuit half-open — trying again..."
      else
        raise "CircuitBreaker OPEN: service unavailable (retry after #{remaining_time}s)"
      end
    end

    begin
      result = block.call
      on_success
      result
    rescue => e
      on_failure(e)
      raise
    end
  end

  def state
    @state
  end

  def reset!
    @failure_count = 0
    @state         = :closed
    @opened_at     = nil
  end

  private

  def on_success
    @failure_count = 0
    @state         = :closed
  end

  def on_failure(error)
    @failure_count += 1
    if @failure_count >= @failure_threshold || @state == :half_open
      @state     = :open
      @opened_at = Time.now
      puts "Circuit OPENED after #{@failure_count} failures"
    end
  end

  def remaining_time
    (@reset_timeout - (Time.now - @opened_at)).ceil
  end
end

# Usage:
breaker = CircuitBreaker.new(failure_threshold: 3, reset_timeout: 10)

5.times do |i|
  breaker.call { raise "Service down!" }
rescue => e
  puts "Attempt #{i + 1}: #{e.message}"
end

# Attempt 1: Service down!
# Attempt 2: Service down!
# Attempt 3: Service down!
# Circuit OPENED after 3 failures
# Attempt 4: CircuitBreaker OPEN: service unavailable (retry after 10s)
# Attempt 5: CircuitBreaker OPEN: service unavailable (retry after 10s)
```

### Exercise 4

```ruby
# Result type — Ok/Err without exceptions (like Rust's Result)

class Result
  attr_reader :value, :error

  def initialize(ok:, value: nil, error: nil)
    @ok    = ok
    @value = value
    @error = error
  end

  def self.ok(value)
    new(ok: true, value: value)
  end

  def self.err(message)
    new(ok: false, error: message)
  end

  def ok?
    @ok
  end

  def err?
    !@ok
  end

  # Transform the value if ok, pass through if err
  def map
    return self if err?
    begin
      Result.ok(yield(value))
    rescue => e
      Result.err(e.message)
    end
  end

  # Chain operations that also return Results
  def flat_map
    return self if err?
    yield(value)
  end

  # Get value or a default
  def value_or(default)
    ok? ? value : default
  end

  # Raise if error, return value if ok
  def unwrap!
    raise "Result::Error: #{error}" if err?
    value
  end

  def to_s
    ok? ? "Ok(#{value.inspect})" : "Err(#{error.inspect})"
  end
end

# Usage:
def divide(a, b)
  return Result.err("Division by zero") if b == 0
  Result.ok(a.to_f / b)
end

def sqrt(n)
  return Result.err("Cannot take sqrt of negative number") if n < 0
  Result.ok(Math.sqrt(n))
end

# Chain operations:
result = divide(16, 4).flat_map { |n| sqrt(n) }
puts result           # => Ok(2.0)
puts result.value     # => 2.0

bad = divide(10, 0).flat_map { |n| sqrt(n) }
puts bad              # => Err("Division by zero")
puts bad.value_or(0)  # => 0

divide(100, 4)
  .map { |n| n.round }
  .flat_map { |n| sqrt(n) }
# => Ok(5.0)
```
