# Chapter 4 — Methods and Blocks

## Defining Methods

```ruby
def greet(name)
  "Hello, #{name}!"    # last expression is return value
end

puts greet("Yosia")    # => Hello, Yosia!

# Explicit return (when returning early)
def divide(a, b)
  return "Error: division by zero" if b == 0
  a.to_f / b
end
```

The **last expression** in a method is its return value. You rarely write `return` explicitly — only when you want to exit early.

---

## Parameter Types

```ruby
# Default parameters
def greet(name, greeting = "Hello")
  "#{greeting}, #{name}!"
end

greet("Yosia")              # => "Hello, Yosia!"
greet("Yosia", "Hey")       # => "Hey, Yosia!"

# Keyword arguments (named params)
def create_user(name:, age:, admin: false)
  "#{name}, age #{age}, admin: #{admin}"
end

create_user(name: "Yosia", age: 30)          # order doesn't matter
create_user(age: 30, name: "Yosia")          # same result
create_user(name: "Yosia", age: 30, admin: true)

# Splat (*args) — variable number of arguments
def sum(*numbers)
  numbers.sum    # numbers is an array
end

sum(1, 2, 3)     # => 6
sum(1, 2, 3, 4, 5)  # => 15

# Double splat (**kwargs) — variable keyword args
def configure(**options)
  options.each { |k, v| puts "#{k}: #{v}" }
end

configure(host: "localhost", port: 3000)

# Combining everything
def complex(required, optional = "default", *rest, key:, other: nil, **more)
  [required, optional, rest, key, other, more]
end
```

---

## Blocks — The Heart of Ruby

A block is a chunk of code you pass to a method. It's one of Ruby's most distinctive features.

```ruby
# Single-line block with { }
[1,2,3].each { |n| puts n }

# Multi-line block with do...end
[1,2,3].each do |n|
  puts n * 2
end
```

Inside a method, use `yield` to call the block:

```ruby
def repeat(n)
  n.times { yield }
end

repeat(3) { print "hello " }   # hello hello hello

# yield with arguments
def transform(value)
  yield(value)
end

transform(5) { |n| n * 2 }   # => 10
transform("hello") { |s| s.upcase }  # => "HELLO"

# Check if block given
def maybe_yield
  if block_given?
    yield
  else
    "no block provided"
  end
end
```

---

## Capturing Blocks with &

You can capture a block as a named parameter using `&`:

```ruby
def run(&block)
  puts "Before"
  block.call        # same as yield
  puts "After"
end

run { puts "Inside!" }
# Before
# Inside!
# After

# You can store it and call it later:
def save_for_later(&block)
  @saved = block
end

def run_it
  @saved.call if @saved
end
```

---

## Procs and Lambdas

A **Proc** is a block stored in a variable:

```ruby
double = Proc.new { |n| n * 2 }
double.call(5)   # => 10
double.(5)       # same
double[5]        # same

square = proc { |n| n ** 2 }
square.call(4)   # => 16

# Pass a proc as a block with &:
[1,2,3].map(&double)   # => [2,4,6]
```

A **lambda** is a stricter Proc:

```ruby
triple = lambda { |n| n * 3 }
triple.call(5)    # => 15

# Stabby lambda (preferred modern syntax)
add = ->(a, b) { a + b }
add.call(3, 4)    # => 7
add.(3, 4)        # same

# Lambda checks argument count:
triple.call(1, 2)    # raises ArgumentError (wrong number of args)
# Proc would just ignore extra args

# Lambda return exits the lambda, not the enclosing method
# Proc return exits the enclosing method
```

### When to use which:

```ruby
# Proc: as a block you want to reuse
logger = proc { |msg| puts "[LOG] #{msg}" }
["a", "b"].each(&logger)

# Lambda: as a function stored in a variable
validate_email = ->(email) {
  email.match?(/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
}
validate_email.call("yosia@example.com")   # => true
```

---

## Method Objects

Methods are objects too:

```ruby
def double(n)
  n * 2
end

m = method(:double)   # get a Method object
m.call(5)             # => 10
[1,2,3].map(&m)       # => [2,4,6]

# Useful with built-in methods:
["1","2","3"].map(&method(:Integer))   # => [1,2,3]
[1,nil,2,nil].select(&method(:Integer))  # hmm... different
```

---

## The `&:method` Shorthand

```ruby
# These are equivalent:
["hello", "world"].map { |s| s.upcase }
["hello", "world"].map(&:upcase)

[1,-2,3,-4].select { |n| n.positive? }
[1,-2,3,-4].select(&:positive?)

["hello", "  world  "].map(&:strip)
```

`&:upcase` converts the symbol `:upcase` to a Proc that calls `.upcase` on its argument. This works because `Symbol` has a `to_proc` method:

```ruby
:upcase.to_proc   # => #<Proc: Symbol#upcase>
```

---

## Closures — Blocks Remember Their Context

A block captures the variables from where it was defined:

```ruby
def make_counter(start = 0)
  count = start
  increment = -> { count += 1; count }
  decrement = -> { count -= 1; count }
  get       = -> { count }
  [increment, decrement, get]
end

inc, dec, get = make_counter(10)
inc.call   # => 11
inc.call   # => 12
dec.call   # => 11
get.call   # => 11
```

`count` is captured by all three lambdas. They share it. When the method returns, `count` lives on inside the closures. This is a **closure** — a function that closes over its surrounding variables.

---

## Enumerable — The Power of Blocks

Ruby's `Enumerable` module gives arrays and hashes a huge set of methods, all powered by blocks:

```ruby
numbers = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3]

numbers.map    { |n| n * 2 }         # transform each
numbers.select { |n| n > 4 }         # keep matching
numbers.reject { |n| n > 4 }         # remove matching
numbers.find   { |n| n > 4 }         # first matching
numbers.all?   { |n| n > 0 }         # all match?
numbers.any?   { |n| n > 8 }         # any match?
numbers.none?  { |n| n > 10 }        # none match?
numbers.count  { |n| n > 4 }         # count matching
numbers.sum    { |n| n * 2 }         # sum of transformed
numbers.min_by { |n| -n }            # min by criteria
numbers.max_by { |n| n }             # max by criteria
numbers.sort_by { |n| n }            # sort by criteria
numbers.group_by { |n| n % 2 == 0 ? :even : :odd }
# => { odd: [3,1,1,5,9,5,3], even: [4,2,6] }

numbers.reduce(0) { |sum, n| sum + n }  # fold/accumulate
numbers.each_slice(3).to_a              # groups of 3
numbers.each_cons(3).to_a               # sliding window of 3
numbers.flat_map { |n| [n, n * 2] }     # map then flatten
numbers.zip([1,2,3,4,5,6,7,8,9,10])    # pair with another array
numbers.take_while { |n| n < 5 }        # take until condition fails
numbers.drop_while { |n| n < 5 }        # drop until condition fails
```

---

## Your Program: Text Statistics

```ruby
# textstats.rb — analyze a text file
# Usage: ruby textstats.rb file.txt

if ARGV.empty?
  puts "Usage: textstats.rb file.txt"
  exit 1
end

text = File.read(ARGV[0])

lines  = text.lines.map(&:chomp)
words  = text.split(/\s+/).reject(&:empty?)
chars  = text.chars

# Word frequency
word_freq = words
  .map(&:downcase)
  .map { |w| w.gsub(/[^a-z]/, '') }
  .reject(&:empty?)
  .group_by { |w| w }
  .transform_values(&:count)
  .sort_by { |_, count| -count }

# Sentence count (rough)
sentences = text.split(/[.!?]+/).reject { |s| s.strip.empty? }

# Average word length
avg_word_len = words.sum(&:length).to_f / words.length

puts "=== Text Statistics ==="
puts "Lines:          #{lines.length}"
puts "Words:          #{words.length}"
puts "Characters:     #{chars.length}"
puts "Sentences:      #{sentences.length}"
puts "Unique words:   #{word_freq.length}"
puts "Avg word len:   #{avg_word_len.round(2)}"
puts "Avg words/line: #{(words.length.to_f / lines.length).round(2)}"
puts ""
puts "=== Top 10 Words ==="
word_freq.first(10).each_with_index do |(word, count), i|
  bar = "█" * [count, 20].min
  puts "#{(i+1).to_s.rjust(2)}. #{word.ljust(15)} #{count.to_s.rjust(4)} #{bar}"
end
```

---

## Exercises

1. Write `compose` that takes two functions and returns their composition: `f = compose(method(:double), method(:triple)); f.call(5)` → 30
2. Write `memoize` that wraps any method and caches its results (hint: use a hash as cache, block to wrap the call)
3. Implement `my_map`, `my_select`, `my_reduce` from scratch using `each`
4. Write a method `retry_on_failure(times:, &block)` that retries a block N times on exception

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| Default params | `def f(x, y = 0)` |
| Keyword params | `def f(name:, age: nil)` |
| `*args` / `**kwargs` | variable arg count |
| `yield` | call the passed block |
| `block_given?` | check if a block was passed |
| Proc vs lambda | lambda checks args + returns locally |
| `&:method` | shorthand: `map(&:upcase)` |
| Closure | block captures surrounding variables |
| Enumerable | `map`, `select`, `reduce`, `group_by`, and 40+ more |

---

## Solutions

### Exercise 1

```ruby
# compose — function composition
# f = compose(g, h) means f(x) = g(h(x))

def compose(f, g)
  ->(x) { f.call(g.call(x)) }
end

def double(n) = n * 2
def triple(n) = n * 3
def square(n) = n ** 2

f = compose(method(:double), method(:triple))
f.call(5)   # => 30  (triple(5)=15, double(15)=30)

g = compose(method(:square), method(:double))
g.call(3)   # => 36  (double(3)=6, square(6)=36)

# Chain multiple functions using reduce:
def compose_all(*fns)
  fns.reduce { |f, g| compose(f, g) }
end

pipeline = compose_all(method(:double), method(:triple), method(:square))
pipeline.call(2)  # square(2)=4, triple(4)=12, double(12)=24
# => 24
```

### Exercise 2

```ruby
# memoize — cache method results to avoid recomputation

def memoize(&block)
  cache = {}
  ->(n) {
    cache[n] ||= block.call(n)
  }
end

# Example: expensive fibonacci without memoization
def fib_slow(n)
  return n if n <= 1
  fib_slow(n - 1) + fib_slow(n - 2)
end

# With memoization (using a hash directly):
def fib_fast
  cache = { 0 => 0, 1 => 1 }
  ->(n) {
    cache[n] ||= fib_fast.call(n - 1) + fib_fast.call(n - 2)
  }
end

# More general: memoize any method with a wrapper
def make_memoized(obj, method_name)
  cache      = {}
  original   = obj.method(method_name)
  memoized   = ->(n) { cache[n] ||= original.call(n) }
  memoized
end

# Usage:
slow_square = ->(n) { sleep(0.1); n * n }   # simulate expensive op

fast_square = memoize { |n| n * n }
fast_square.call(5)   # => 25 (computed)
fast_square.call(5)   # => 25 (from cache, instant)
fast_square.call(6)   # => 36 (computed)
```

### Exercise 3

```ruby
# my_map, my_select, my_reduce — built from scratch using each

def my_map(collection)
  result = []
  collection.each { |item| result << yield(item) }
  result
end

def my_select(collection)
  result = []
  collection.each { |item| result << item if yield(item) }
  result
end

def my_reduce(collection, initial = nil)
  accumulator = initial
  collection.each do |item|
    if accumulator.nil?
      accumulator = item   # use first element as seed if no initial given
    else
      accumulator = yield(accumulator, item)
    end
  end
  accumulator
end

# Tests:
numbers = [1, 2, 3, 4, 5]

my_map(numbers) { |n| n * 2 }
# => [2, 4, 6, 8, 10]

my_select(numbers) { |n| n.odd? }
# => [1, 3, 5]

my_reduce(numbers, 0) { |sum, n| sum + n }
# => 15

my_reduce(numbers) { |product, n| product * n }
# => 120

# Works on strings too:
my_map(["hello", "world"]) { |s| s.upcase }
# => ["HELLO", "WORLD"]
```

### Exercise 4

```ruby
# retry_on_failure — retry a block N times on exception

def retry_on_failure(times:, delay: 0, &block)
  attempts = 0
  begin
    attempts += 1
    block.call
  rescue => e
    if attempts < times
      puts "Attempt #{attempts} failed: #{e.message}. Retrying..." if delay > 0 || true
      sleep(delay) if delay > 0
      retry
    else
      raise RuntimeError, "Failed after #{times} attempts. Last error: #{e.message}"
    end
  end
end

# Usage: unstable operation that might fail
call_count = 0
result = retry_on_failure(times: 3) do
  call_count += 1
  raise "Network error" if call_count < 3   # fails twice, succeeds on 3rd
  "success!"
end

puts result       # => "success!"
puts call_count   # => 3

# With delay between retries:
# retry_on_failure(times: 5, delay: 1.0) do
#   HTTParty.get("https://flaky-api.example.com/data")
# end

# Raises after exhausting retries:
begin
  retry_on_failure(times: 2) { raise "Always fails" }
rescue RuntimeError => e
  puts e.message   # => "Failed after 2 attempts. Last error: Always fails"
end
```
