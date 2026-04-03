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

---

## Solutions

### Exercise 1

```ruby
# concurrent_grep.rb — search multiple files in parallel using threads
# Usage: ruby concurrent_grep.rb pattern file1 file2 ...

if ARGV.length < 2
  puts "Usage: concurrent_grep.rb pattern file1 file2 ..."
  exit 1
end

pattern = Regexp.new(ARGV[0])
files   = ARGV[1..]

# Thread-safe way to collect results
results = []
mutex   = Mutex.new

threads = files.map do |file|
  Thread.new do
    unless File.exist?(file)
      mutex.synchronize { results << { file: file, error: "not found" } }
      next
    end

    matches = []
    File.foreach(file).with_index(1) do |line, num|
      matches << { line: num, text: line.chomp } if line.match?(pattern)
    end

    mutex.synchronize { results << { file: file, matches: matches } }
  rescue => e
    mutex.synchronize { results << { file: file, error: e.message } }
  end
end

threads.each(&:join)

# Print results sorted by filename
results.sort_by { |r| r[:file] }.each do |result|
  if result[:error]
    puts "#{result[:file]}: ERROR: #{result[:error]}"
  elsif result[:matches].empty?
    # skip files with no matches
  else
    result[:matches].each do |m|
      puts "#{result[:file]}:#{m[:line]}: #{m[:text]}"
    end
  end
end

total = results.sum { |r| r[:matches]&.length || 0 }
puts "\n#{total} match(es) in #{files.length} file(s)"
```

### Exercise 2

```ruby
# thread_pool.rb — N worker threads processing a queue of jobs

require 'thread'

class ThreadPool
  def initialize(size)
    @size    = size
    @queue   = Queue.new
    @results = Queue.new
    @workers = []
    start_workers
  end

  def submit(job = nil, &block)
    work = job || block
    raise ArgumentError, "No job given" unless work
    @queue << work
  end

  # Submit a job and track it with a future-like object
  def submit_with_result(&block)
    result_slot = Queue.new
    @queue << -> { result_slot << block.call }
    result_slot
  end

  def shutdown
    @size.times { @queue << :stop }
    @workers.each(&:join)
  end

  def process_all(jobs)
    jobs.each { |job| submit { job } }
    # Not a real future — for demo purposes, just drain
  end

  private

  def start_workers
    @size.times do
      @workers << Thread.new do
        loop do
          job = @queue.pop
          break if job == :stop
          begin
            job.call
          rescue => e
            puts "Worker error: #{e.message}"
          end
        end
      end
    end
  end
end

# Usage:
pool = ThreadPool.new(4)
mutex = Mutex.new
results = []

20.times do |i|
  pool.submit do
    sleep(rand(0.01..0.1))   # simulate work
    mutex.synchronize { results << i * i }
  end
end

pool.shutdown
puts results.sort.inspect
# => [0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144, 169, 196, 225, 256, 289, 324, 361]
```

### Exercise 3

```ruby
# rate_limiter.rb — allow at most N calls per second using Mutex

class RateLimiter
  def initialize(max_calls:, per_seconds: 1.0)
    @max_calls   = max_calls
    @per_seconds = per_seconds
    @calls       = []
    @mutex       = Mutex.new
  end

  # Returns true if allowed, false if rate limit exceeded
  def allow?
    @mutex.synchronize do
      now = Time.now.to_f
      # Remove calls outside the window
      @calls.reject! { |t| t < now - @per_seconds }
      if @calls.length < @max_calls
        @calls << now
        true
      else
        false
      end
    end
  end

  # Block until allowed, then execute
  def throttle(&block)
    loop do
      if allow?
        return block.call
      else
        sleep(0.01)   # wait 10ms before retrying
      end
    end
  end
end

# Usage:
limiter = RateLimiter.new(max_calls: 5, per_seconds: 1.0)

# Test: try to make 10 calls quickly — only 5 should go through per second
threads = 10.times.map do |i|
  Thread.new do
    if limiter.allow?
      puts "Call #{i}: ALLOWED at #{Time.now.strftime('%H:%M:%S.%3N')}"
    else
      puts "Call #{i}: RATE LIMITED"
    end
  end
end

threads.each(&:join)
# First 5 calls: ALLOWED
# Last 5 calls: RATE LIMITED
```

### Exercise 4

```ruby
# producer_consumer_fiber.rb — producer-consumer pipeline using fibers

# Producer fiber: generates values
producer = Fiber.new do
  puts "Producer: starting"
  10.times do |i|
    item = "item_#{i}"
    puts "Producer: made #{item}"
    Fiber.yield item   # hand item to consumer
  end
  nil   # signal end
end

# Consumer fiber: processes values from producer
consumer = Fiber.new do |first_item|
  item = first_item
  loop do
    break if item.nil?
    puts "Consumer: processing #{item}"
    result = item.upcase
    puts "Consumer: done with #{result}"
    item = Fiber.yield result   # ask for next item
  end
  puts "Consumer: finished"
end

# Pipeline: drive the producer-consumer loop
results = []
item = producer.resume   # start producer, get first item

while item
  result = consumer.resume(item)   # send to consumer, get processed result
  results << result if result
  item = producer.resume           # get next item from producer
end

consumer.resume(nil)   # signal consumer to stop

puts "\nResults: #{results.inspect}"
# Results: ["ITEM_0", "ITEM_1", "ITEM_2", ...]

# --- A more elegant pipeline version using lazy enumerators ---
producer_enum = Enumerator.new do |y|
  10.times { |i| y << "item_#{i}" }
end

results = producer_enum
  .lazy
  .map(&:upcase)          # "consumer" transform step 1
  .select { |s| s =~ /[02468]/ }  # filter: only even-numbered items
  .first(3)               # take just 3

puts results.inspect
# => ["ITEM_0", "ITEM_2", "ITEM_4"]
```
