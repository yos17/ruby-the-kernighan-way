# Chapter 4 — Methods, Blocks, Procedures

You have been using methods and blocks since the first chapter. This chapter is where they stop being background syntax and become tools you can shape directly. The programs are a `pipeline` that composes transformations, a `memoizer` that wraps a slow function, and an `events` bus that stores listeners and calls them later.

The point is not abstract functional programming. The point is that Ruby lets you pass behavior around as easily as data, and once you see that clearly, a lot of everyday code gets smaller.

## Defining methods, properly

The basic form:

```ruby
def greet(name)
  "Hello, #{name}!"
end

greet("Yosia")   # => "Hello, Yosia!"
```

Default values:

```ruby
def greet(name = "World")
  "Hello, #{name}!"
end

greet           # => "Hello, World!"
greet("Yosia")  # => "Hello, Yosia!"
```

Keyword arguments — clearer at the call site than positional arguments:

```ruby
def connect(host:, port: 80, ssl: false)
  "#{ssl ? "https" : "http"}://#{host}:#{port}"
end

connect(host: "example.com")              # => "http://example.com:80"
connect(host: "example.com", ssl: true)   # => "https://example.com:80"
```

Default rule: **two or more arguments → use keywords.** The cost is small (slightly more typing at the call site); the benefit is calls that read clearly without checking the method signature.

Splat — accept any number of positional arguments:

```ruby
def shout(*words)
  words.map(&:upcase).join(" ")
end

shout("hello", "ruby", "world")   # => "HELLO RUBY WORLD"
```

Double-splat — accept any keyword arguments as a hash:

```ruby
def log(message, **fields)
  puts "#{message} #{fields.map { |k, v| "#{k}=#{v}" }.join(" ")}"
end

log("user signed in", user: "yosia", ip: "127.0.0.1")
# => user signed in user=yosia ip=127.0.0.1
```

Endless methods (Ruby 3+) — for one-line definitions:

```ruby
def square(n) = n * n
def greet(name) = "Hello, #{name}!"
```

Use endless methods for genuinely-one-line bodies. For anything bigger, use `def ... end`.

## Return values

The last expression is the return value. Explicit `return` is for early exits:

```ruby
def divide(a, b)
  return "cannot divide by zero" if b == 0
  a / b
end
```

You used this in `calc.rb`. It's the dominant pattern.

## Blocks

A block is a chunk of code passed to a method. You've passed lots:

```ruby
[1, 2, 3].each { |n| puts n }       # one-line
[1, 2, 3].each do |n|               # multi-line
  puts n
end
```

`{ }` and `do/end` are the same thing. By convention: `{ }` for one-liners, `do/end` for multi-line. The block isn't an argument *exactly* — it's a special slot every method has.

To run the block from inside a method, use `yield`:

```ruby
def twice
  yield
  yield
end

twice { puts "hi" }   # prints "hi" twice
```

Pass arguments to the block via `yield`:

```ruby
def greet_each(names)
  names.each { |n| yield n }
end

greet_each(["Alice", "Bob"]) { |name| puts "Hello, #{name}!" }
```

`block_given?` checks if the caller passed a block:

```ruby
def maybe_log(message)
  if block_given?
    yield message
  else
    puts message
  end
end

maybe_log("hello")                       # => hello
maybe_log("hello") { |m| puts m.upcase } # => HELLO
```

## Capturing the block as a variable: `&block`

When you want to *pass the block elsewhere* or store it, capture it with `&block` in the parameter list:

```ruby
def with_logging(&block)
  puts "before"
  result = block.call
  puts "after"
  result
end

with_logging { 1 + 1 }   # prints "before", then "after", returns 2
```

Inside the method, `block` is a regular variable holding a `Proc`. You can `block.call(args)` it, store it, pass it on.

To call it with arguments: `block.call(a, b)` or the shorthand `block.(a, b)` or `block[a, b]`.

## The `&` operator, in one rule

`&` converts between a block and a Proc. That is the whole story; the direction depends on where it appears.

- `def foo(&blk)` — in a parameter list, `&` *captures* the incoming block as a Proc named `blk`.
- `foo(&prc)` — at a call site, `&` *unpacks* the Proc `prc` into the block slot.

So a block becomes a Proc on the way in, and a Proc becomes a block on the way out. The same `&` is doing inverse jobs at the two ends.

Forwarding a block is where this matters. If a method takes a block and wants to hand it to another method, you must capture and re-pass:

```ruby
def each_doubled(arr, &blk)
  arr.each { |x| blk.call(x * 2) }   # use the captured Proc
end

def each_doubled_clean(arr, &blk)
  arr.map { |x| x * 2 }.each(&blk)   # forward the block on
end

each_doubled_clean([1, 2, 3]) { |n| puts n }
# => 2
# => 4
# => 6
```

Without the `&blk` parameter, you can't name the block. Without the `&blk` at the call site, `each` would receive `blk` as a regular positional argument and complain.

## Procs and lambdas

A **Proc** is a block stored as an object. A **Lambda** is a Proc with two stricter behaviors:

- **Argument checking:** lambdas raise if you pass the wrong number of arguments. Procs don't.
- **`return`:** `return` in a lambda returns from the lambda. `return` in a proc returns from the *enclosing method* (often surprising).

```ruby
square_proc   = Proc.new { |x| x * x }
square_lambda = ->(x) { x * x }

square_proc.call(3)     # => 9
square_lambda.(3)       # => 9    (.() shorthand)
square_lambda[3]        # => 9    ([] shorthand)
```

Use `->(args) { body }` (called "stabby lambda") for almost all small functions. Only use `Proc.new` (or the bare `proc { }`) when you want the looser semantics — which is rarely.

When you have a method that takes a block, you can pass a lambda with `&`:

```ruby
double = ->(x) { x * 2 }
[1, 2, 3].map(&double)   # => [2, 4, 6]
```

`&` here converts the lambda to a block. The reverse — capturing a block as a lambda — is `&block` in a parameter list (above).

## Symbol#to_proc — the `&:method` shorthand

This idiom is everywhere:

```ruby
[1, 2, 3].map(&:to_s)         # => ["1", "2", "3"]
["a", "b"].map(&:upcase)      # => ["A", "B"]
[1, -2, 3].select(&:positive?) # => [1, 3]
```

`&:upcase` is `&` applied to the symbol `:upcase`. Ruby's `Symbol#to_proc` returns a lambda equivalent to `->(x) { x.upcase }`. You'll write this constantly.

## Numbered block params (`_1`, `_2`) and the `it` parameter

Newer Ruby gives you two more shortcuts for short blocks:

```ruby
[1, 2, 3].map { _1 * 2 }     # => [2, 4, 6]    (numbered params)
[1, 2, 3].map { it * 2 }     # => [2, 4, 6]    (it, Ruby 3.4+)

{ a: 1, b: 2 }.each { puts "#{_1}=#{_2}" }   # iterates with _1=key, _2=value
```

`it` is the most beginner-friendly — it reads like English. `_1`/`_2` is useful when you have multiple block parameters (since `it` only refers to the first). For complex blocks with named meaning, write out `do |x| ... end`.

## pipeline.rb

A chainable transformation runner. Define a sequence of small functions, then apply them in order to a value.

```ruby
# pipeline.rb — chain transformations together
# Usage: ruby pipeline.rb (demo prints; or require this file from another)

class Pipeline
  def initialize(*steps)
    @steps = steps
  end

  def call(input)
    @steps.reduce(input) { |value, step| step.call(value) }
  end

  def then(step)
    Pipeline.new(*@steps, step)
  end
end

# A few small transforms
strip_whitespace = ->(s) { s.strip }
to_lower         = ->(s) { s.downcase }
remove_punct     = ->(s) { s.gsub(/[[:punct:]]/, "") }
words            = ->(s) { s.split }
top_3            = ->(arr) { arr.tally.sort_by { |w, c| [-c, w] }.first(3) }

clean = Pipeline.new(strip_whitespace, to_lower, remove_punct)
top_words = clean.then(words).then(top_3)

p top_words.call("  Hello, hello! World hello world.  ")
# => [["hello", 3], ["world", 2]]
```

What's new.

The `Pipeline` class wraps an array of step functions and runs them with `reduce`. Each step takes the previous step's output as input.

`reduce(initial) { |acc, x| ... }` — start with `initial`, fold each element in by combining it with the running accumulator. The accumulator here is the running value of the data flowing through the pipeline.

`then(step)` returns a *new* Pipeline with the extra step appended. The original is unchanged — composition without mutation. This is the core idea of functional pipelines.

The five lambdas at the bottom each do one small thing. The pipeline composes them. Adding a step never requires editing existing code — you just `.then` another lambda.

(File: `examples/pipeline.rb`.)

## memoizer.rb

A method-call cache: the first call computes, subsequent calls with the same arguments return the cached answer.

```ruby
# memoizer.rb — wrap any callable with a result cache
# Usage: ruby memoizer.rb (demo)

def memoize(fn)
  cache = {}
  ->(*args) { cache.fetch(args) { cache[args] = fn.call(*args) } }
end

# A deliberately slow function
slow_square = ->(n) {
  sleep 0.5
  n * n
}

fast_square = memoize(slow_square)

require "benchmark"
puts Benchmark.measure { 5.times { fast_square.call(4) } }
# Real time: ~0.5 seconds (only the first call is slow)
puts fast_square.call(4)   # => 16
puts fast_square.call(5)   # => 25 (cache miss)
puts fast_square.call(4)   # => 16 (cache hit, instant)
```

What's new.

`memoize(fn)` takes a callable and returns a *new* callable that caches results. The returned lambda captures `cache` and `fn` by closure — they live as long as the lambda lives.

`cache.fetch(args) { cache[args] = fn.call(*args) }` — `Hash#fetch` with a block: if the key exists, return the value; otherwise, run the block and return its result. The block also writes the value back to the cache, so future lookups hit.

Closures are a big idea: a lambda *closes over* its surrounding scope. The variables it references at definition time stay accessible, even after the surrounding method returns.

(File: `examples/memoizer.rb`.)

## events.rb

A tiny pub/sub event bus. Listeners subscribe to topics; publishing a topic invokes every subscribed listener.

```ruby
# events.rb — a minimal pub/sub event bus
# Usage: ruby events.rb (demo)

class EventBus
  def initialize
    @listeners = Hash.new { |h, k| h[k] = [] }
  end

  def on(topic, &handler)
    @listeners[topic] << handler
    handler
  end

  def off(topic, handler)
    @listeners[topic].delete(handler)
  end

  def emit(topic, *args, **kwargs)
    @listeners[topic].each { |h| h.call(*args, **kwargs) }
  end
end

bus = EventBus.new

bus.on(:user_signed_in) { |user:| puts "welcome, #{user}" }
bus.on(:user_signed_in) { |user:| puts "logging signin for #{user}" }

bus.emit(:user_signed_in, user: "yosia")
# => welcome, yosia
# => logging signin for yosia
```

What's new.

`Hash.new { |h, k| h[k] = [] }` — a hash with a *default block*. When you ask for a missing key, the block runs, builds a default value (here, an empty array), stores it, and returns it. Without this, you'd write `@listeners[topic] ||= []` everywhere.

`*args, **kwargs` — splat the positional args and the keyword args. The handler gets called with whatever the caller passed to `emit`.

`&handler` captures the block as a Proc you can store in the array.

This 13-line class is the basis of every event-driven framework in Ruby. The Rails router uses a more elaborate version. The actor-style libraries are this idea on threads.

(File: `examples/events.rb`.)

## Common pitfalls

Forgetting `&block` when forwarding. If a method takes a block but you need to hand it to another method, you must declare `&blk` and pass it back with `&blk`. Without the explicit capture, the block exists only for `yield` inside this method — there's no name to forward.

Proc vs lambda return semantics. `return` inside a `Proc.new { ... }` returns from the *enclosing method*, often jumping out of code you didn't expect. `return` inside a `->{ ... }` returns only from the lambda. When in doubt, use a lambda. Reach for a Proc only when you specifically want the loose argument-matching and the long-jump return.

`&:method` only works for zero-arg methods. `[1, 2].map(&:succ)` works because `succ` takes no arguments. `[1, 2].map(&:+)` does not — `+` needs an operand. For anything that takes arguments, write the block: `[1, 2].map { |n| n + 10 }`.

`_1`/`_2`/`it` are convenience-only. They read well in three-character blocks like `{ it.upcase }`. They read poorly when the block is long, when meaning matters, or when nested blocks each have their own implicit param. In shared code or any block over a few lines, name the parameter: `do |order| ... end`.

## What you learned

| Concept | Key point |
|---|---|
| `def m(a, b: 1, *rest, **kw)` | positional, keyword, splat, double-splat args |
| `def m(a) = a + 1` | endless methods (one-liners) |
| `yield`, `block_given?` | call the block; check if one was passed |
| `&block` | capture the block as a Proc parameter |
| `proc { }` vs `->( ) { }` | Proc (loose) vs Lambda (strict, `.()`-callable) |
| `&:method` | symbol-to-proc shorthand for `{ |x| x.method }` |
| `_1`, `_2`, `it` | implicit block parameters (short blocks only) |
| `reduce(init) { |acc, x| ... }` | fold a collection into a single value |
| `Hash.new { |h, k| h[k] = [] }` | hash with computed default |
| Closures | lambdas/blocks capture their surrounding scope |
| `lambda.call(args)` / `.(args)` / `[args]` | three ways to invoke |

## Going deeper

Read the source of `Enumerable` in the Ruby repo (`enum.c` plus the Ruby-level helpers). Forty-something methods all built on `each` — the same trick you'd use yourself, written once for the whole language.

Read Chapter 6 of David A. Black's *The Well-Grounded Rubyist*. The block / Proc / lambda / `&` material there is the canonical longer treatment, and it pairs well with this chapter.

Build an Either/Result type with lambdas only — no classes:

```ruby
Ok  = ->(value) { ->(on_ok, _on_err) { on_ok.call(value) } }
Err = ->(reason) { ->(_on_ok, on_err) { on_err.call(reason) } }

result = Ok.call(42)
result.call(->(v) { puts "got #{v}" }, ->(e) { puts "err: #{e}" })
# => got 42
```

Doing this once is a strong lesson in how much "object-oriented" structure dissolves into closures.

## Exercises

1. **pipeline reverse**: extend `Pipeline` with a `reverse_steps` method that returns a new Pipeline with steps in reverse order. Useful for "undo" pipelines. Starter: `exercises/1_pipeline_reverse.rb`.

2. **pipeline tap**: add a `tap_with` method that inserts a side-effect step (like logging) without changing the value flowing through. Starter: `exercises/2_pipeline_tap.rb`.

3. **memoizer with cache eviction**: extend `memoize` to take a `max_size:` keyword. When the cache exceeds that many entries, drop the oldest. Hint: `cache.shift` removes the oldest entry. Starter: `exercises/3_memoizer_lru.rb`.

4. **events.once**: add a `once(topic, &handler)` method that fires the handler at most once, then auto-unsubscribes. Hint: a wrapper lambda that calls the original then removes itself. Starter: `exercises/4_events_once.rb`.

5. **events.wait_for**: add a method `wait_for(topic)` that returns a Proc you can call to wait until the topic fires next. (Use a `Thread::Queue` or a simple flag with sleep.) Starter: `exercises/5_events_wait.rb`.

6. **compose.rb**: write `compose(*fns)` that returns a lambda chaining the given lambdas in order — `compose(a, b, c).call(x) == c.call(b.call(a.call(x)))`. Then write the same for right-to-left composition. Starter: `exercises/6_compose.rb`.
