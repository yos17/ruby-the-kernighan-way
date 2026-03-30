# Chapter 9 — Error Handling

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

---

## raise and rescue

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
