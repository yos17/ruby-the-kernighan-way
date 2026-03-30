# Chapter 11 — Concurrency

## Threads — Running Code in Parallel

```ruby
# Create a thread
t = Thread.new do
  puts "Thread running!"
  sleep 1
  puts "Thread done!"
end

puts "Main thread continues..."
t.join   # wait for thread to finish
puts "All done"

# With return value
t = Thread.new { 2 + 2 }
result = t.value   # waits and returns 4

# Multiple threads
threads = 5.times.map do |i|
  Thread.new do
    sleep rand(0.1..1.0)
    puts "Thread #{i} done"
  end
end

threads.each(&:join)
puts "All threads finished"
```

---

## Thread Safety — The Problem

When multiple threads share data, things can go wrong:

```ruby
counter = 0
threads = 100.times.map do
  Thread.new { counter += 1 }   # NOT safe!
end
threads.each(&:join)
puts counter   # might not be 100!
```

`counter += 1` is actually three operations: read, add, write. Two threads can interleave these, losing updates.

### Mutex — the fix

```ruby
counter = 0
mutex   = Mutex.new

threads = 100.times.map do
  Thread.new do
    mutex.synchronize { counter += 1 }  # only one thread at a time
  end
end
threads.each(&:join)
puts counter   # always 100
```

---

## The GIL (Global Interpreter Lock)

MRI Ruby (the standard implementation) has a GIL — only one thread runs Ruby code at a time. This means threads help with **I/O-bound** work (file reading, HTTP requests) but not **CPU-bound** work (calculations).

For CPU-bound parallelism, use `Process.fork` (Unix) or `ractor` (Ruby 3+).

---

## Ractor — True Parallelism (Ruby 3+)

```ruby
# Ractors share no mutable state — true isolation
r = Ractor.new do
  Ractor.receive + " world"
end

r.send("hello")
puts r.take   # => "hello world"

# CPU-bound parallel work:
results = 4.times.map do |i|
  Ractor.new(i) do |n|
    (1..1_000_000).sum * n   # runs in parallel
  end
end.map(&:take)
```

---

## Async I/O with Threads — A Practical Example

```ruby
# Fetch multiple URLs concurrently
require 'net/http'
require 'uri'

def fetch(url)
  uri      = URI(url)
  response = Net::HTTP.get_response(uri)
  { url: url, status: response.code, length: response.body.length }
rescue => e
  { url: url, error: e.message }
end

urls = %w[
  https://httpbin.org/delay/1
  https://httpbin.org/delay/2
  https://httpbin.org/delay/1
]

start = Time.now
results = urls.map do |url|
  Thread.new { fetch(url) }
end.map(&:value)

puts "Done in #{(Time.now - start).round(1)}s"
results.each { |r| puts r.inspect }
# Sequential: ~4s. Concurrent with threads: ~2s.
```

---

## Fiber — Cooperative Concurrency

A Fiber is like a thread but you control when it yields:

```ruby
fiber = Fiber.new do
  puts "Step 1"
  Fiber.yield        # pause here
  puts "Step 2"
  Fiber.yield        # pause again
  puts "Step 3"
end

fiber.resume   # prints "Step 1"
fiber.resume   # prints "Step 2"
fiber.resume   # prints "Step 3"

# Producer/consumer with fibers:
producer = Fiber.new do
  5.times do |i|
    Fiber.yield i * 10
  end
  nil
end

loop do
  value = producer.resume
  break if value.nil?
  puts "Got: #{value}"
end
```

Fibers are the foundation of Ruby's `async`/`await`-style patterns.

---

## Exercises

1. Write a concurrent `grep` that searches multiple files in parallel using threads
2. Implement a thread pool — N worker threads processing a queue of jobs
3. Build a `rate_limiter` using a Mutex that allows at most N calls per second
4. Write a simple producer-consumer pipeline using fibers

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| `Thread.new` | run code concurrently |
| `t.join` | wait for thread to finish |
| `t.value` | get thread return value |
| `Mutex` | protect shared data |
| GIL | threads help with I/O, not CPU |
| `Ractor` | true parallelism (Ruby 3+), no shared state |
| `Fiber` | cooperative concurrency, you control switching |
