# Chapter 7 — Collections in Depth

## Arrays — Beyond the Basics

```ruby
# Creation
Array.new(5, 0)           # => [0,0,0,0,0]
Array.new(5) { |i| i*2 } # => [0,2,4,6,8]
(1..5).to_a               # => [1,2,3,4,5]
"hello".chars             # => ["h","e","l","l","o"]

# Set operations
[1,2,3] | [2,3,4]     # union:        [1,2,3,4]
[1,2,3] & [2,3,4]     # intersection: [2,3]
[1,2,3] - [2,3]       # difference:   [1]
[1,2] + [3,4]         # concatenation: [1,2,3,4]

# Flatten and zip
[[1,2],[3,[4,5]]].flatten    # => [1,2,3,4,5]
[[1,2],[3,4]].flatten(1)     # => [1,2,3,4]
[1,2,3].zip([4,5,6])         # => [[1,4],[2,5],[3,6]]

# Rotate and sample
[1,2,3,4,5].rotate(2)     # => [3,4,5,1,2]
[1,2,3,4,5].sample        # random element
[1,2,3,4,5].sample(3)     # 3 random elements (no repeats)
[1,2,3,4,5].shuffle       # random order

# Partition
[1,2,3,4,5,6].partition { |n| n.even? }
# => [[2,4,6],[1,3,5]]

# each_slice, each_cons
[1,2,3,4,5,6].each_slice(2).to_a
# => [[1,2],[3,4],[5,6]]

[1,2,3,4,5].each_cons(3).to_a
# => [[1,2,3],[2,3,4],[3,4,5]]  (sliding window)

# tally — count occurrences
["a","b","a","c","b","a"].tally
# => {"a"=>3, "b"=>2, "c"=>1}

# flat_map
[[1,2],[3,4]].flat_map { |arr| arr.map { |n| n * 2 } }
# => [2,4,6,8]

# zip and map together
names  = ["Alice", "Bob", "Charlie"]
scores = [85, 92, 78]
names.zip(scores).map { |name, score| "#{name}: #{score}" }
# => ["Alice: 85", "Bob: 92", "Charlie: 78"]
```

---

## Hashes — Beyond the Basics

```ruby
# Creation from arrays
Hash[[:a,:b,:c].zip([1,2,3])]   # => {a:1, b:2, c:3}
[[:a,1],[:b,2]].to_h            # => {a:1, b:2}
(1..5).each_with_object({}) { |n, h| h[n] = n**2 }
# => {1=>1, 2=>4, 3=>9, 4=>16, 5=>25}

# Transformation
{a:1, b:2, c:3}.transform_values { |v| v * 10 }
# => {a:10, b:20, c:30}

{a:1, b:2, c:3}.transform_keys { |k| k.to_s }
# => {"a"=>1, "b"=>2, "c"=>3}

{a:1, b:2, c:3}.filter_map { |k,v| [k, v*2] if v > 1 }
# => [[:b, 4], [:c, 6]]

# Grouping
people = [{name:"Alice",dept:"eng"},{name:"Bob",dept:"sales"},{name:"Carol",dept:"eng"}]
people.group_by { |p| p[:dept] }
# => {"eng"=>[{name:"Alice"...},{name:"Carol"...}], "sales"=>[{name:"Bob"...}]}

# Counting
words = %w[ruby ruby python javascript ruby python]
words.tally
# => {"ruby"=>3, "python"=>2, "javascript"=>1}

# Deep merge
def deep_merge(h1, h2)
  h1.merge(h2) do |key, old, new_val|
    old.is_a?(Hash) && new_val.is_a?(Hash) ? deep_merge(old, new_val) : new_val
  end
end
```

---

## Lazy Enumerators — Infinite Collections

Regular `map`/`select` process ALL elements and return a new array. For large or infinite collections, use lazy evaluation:

```ruby
# Without lazy: generates all 1000 numbers first
(1..1000000).select { |n| n.odd? }.first(5)

# With lazy: stops as soon as we have 5 results
(1..1000000).lazy.select { |n| n.odd? }.first(5)
# => [1, 3, 5, 7, 9]  — much faster!

# Infinite range:
(1..Float::INFINITY).lazy
  .select { |n| n % 3 == 0 }
  .map { |n| n ** 2 }
  .first(5)
# => [9, 36, 81, 144, 225]
# Without lazy, this would loop forever!

# Fibonacci sequence (infinite):
fib = Enumerator.new do |y|
  a, b = 0, 1
  loop do
    y << a        # yield the value
    a, b = b, a+b
  end
end

fib.lazy.first(10)
# => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

fib.lazy.select { |n| n.even? }.first(5)
# => [0, 2, 8, 34, 144]
```

---

## Custom Enumerators

```ruby
# Build an enumerator that yields something
counter = Enumerator.new do |yielder|
  n = 0
  loop do
    yielder.yield n    # same as: yielder << n
    n += 1
  end
end

counter.next    # => 0
counter.next    # => 1
counter.next    # => 2
counter.rewind  # reset
counter.first(5)  # => [0,1,2,3,4]

# Return an enumerator when no block given (Ruby convention)
class WordList
  def initialize(words)
    @words = words
  end

  def each
    return to_enum(:each) unless block_given?  # return enumerator if no block
    @words.each { |w| yield w }
  end
end

wl = WordList.new(%w[hello world ruby])
wl.each                  # => Enumerator
wl.each { |w| puts w }  # => iterates
wl.map(&:upcase)         # works because each returns enumerator
```

---

## Set — Unique Collections

```ruby
require 'set'

s = Set.new([1, 2, 3, 2, 1])  # => #<Set: {1, 2, 3}>
s.add(4)
s.include?(3)    # => true
s.length         # => 4

s1 = Set[1, 2, 3]
s2 = Set[2, 3, 4]
s1 | s2          # union:        {1,2,3,4}
s1 & s2          # intersection: {2,3}
s1 - s2          # difference:   {1}
s1.subset?(Set[1,2,3,4])   # => true
```

`Set` is faster than `Array` for `include?` on large collections (O(1) vs O(n)).

---

## Your Program: CSV Analyzer

```ruby
# csv_analyzer.rb — analyze a CSV file
# Usage: ruby csv_analyzer.rb data.csv [column_name]

require 'csv'

if ARGV.empty?
  puts "Usage: csv_analyzer.rb file.csv [column]"
  exit 1
end

file   = ARGV[0]
column = ARGV[1]

begin
  data = CSV.read(file, headers: true)
rescue => e
  puts "Error reading CSV: #{e.message}"
  exit 1
end

puts "=== CSV Analysis: #{File.basename(file)} ==="
puts "Rows:    #{data.length}"
puts "Columns: #{data.headers.join(', ')}"
puts ""

if column
  unless data.headers.include?(column)
    puts "Column '#{column}' not found. Available: #{data.headers.join(', ')}"
    exit 1
  end

  values = data[column].compact

  # Try numeric analysis
  numbers = values.map { |v| Float(v) rescue nil }.compact
  if numbers.length == values.length
    sorted = numbers.sort
    puts "=== Numeric Analysis: #{column} ==="
    puts "Count:   #{numbers.length}"
    puts "Min:     #{numbers.min}"
    puts "Max:     #{numbers.max}"
    puts "Sum:     #{numbers.sum.round(2)}"
    puts "Mean:    #{(numbers.sum / numbers.length).round(4)}"
    median = sorted.length.odd? ?
             sorted[sorted.length / 2] :
             (sorted[sorted.length/2 - 1] + sorted[sorted.length/2]) / 2.0
    puts "Median:  #{median}"
  else
    # String analysis
    freq = values.tally.sort_by { |_, count| -count }
    puts "=== String Analysis: #{column} ==="
    puts "Unique values: #{freq.length}"
    puts "Top 10:"
    freq.first(10).each do |(val, count)|
      pct = (count.to_f / values.length * 100).round(1)
      bar = "█" * (count * 20 / values.length)
      puts "  #{val.to_s.ljust(20)} #{count.to_s.rjust(4)} (#{pct}%) #{bar}"
    end
  end
else
  puts "=== Column Summary ==="
  data.headers.each do |col|
    values  = data[col].compact
    unique  = values.uniq.length
    missing = data.length - values.length
    puts "  #{col.ljust(20)} #{data.length} rows, #{unique} unique, #{missing} missing"
  end
end
```

---

## Exercises

1. Build `Matrix` as a 2D array wrapper with `+`, `*`, and `transpose`
2. Write `histogram` that takes an array of numbers, groups them into buckets, and prints a bar chart
3. Implement `deep_flatten` that flattens arbitrarily nested arrays without using `.flatten`
4. Build a priority queue using an array sorted by priority

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| Set operations | `\|`, `&`, `-` on arrays |
| `tally` | count occurrences of each value |
| `partition` | split into two arrays |
| `each_slice` / `each_cons` | groups / sliding windows |
| Lazy enumerator | `.lazy` — process on demand, enables infinite sequences |
| `Enumerator.new` | build a custom sequence with a block |
| `to_enum` | return an enumerator when no block given (Ruby convention) |
| `Set` | unique collection, fast `include?` |

---

## Solutions

### Exercise 1

```ruby
# Matrix as a 2D array wrapper with +, *, and transpose

class Matrix
  def initialize(rows)
    @rows = rows.map { |r| r.dup }
  end

  def [](i, j)
    @rows[i][j]
  end

  def rows
    @rows.length
  end

  def cols
    @rows[0].length
  end

  def +(other)
    raise "Incompatible dimensions" unless rows == other.rows && cols == other.cols
    result = Array.new(rows) { |i| Array.new(cols) { |j| @rows[i][j] + other[i, j] } }
    Matrix.new(result)
  end

  def *(other)
    raise "Incompatible dimensions" unless cols == other.rows
    result = Array.new(rows) do |i|
      Array.new(other.cols) do |j|
        (0...cols).sum { |k| @rows[i][k] * other[k, j] }
      end
    end
    Matrix.new(result)
  end

  def transpose
    result = Array.new(cols) { |j| Array.new(rows) { |i| @rows[i][j] } }
    Matrix.new(result)
  end

  def to_s
    @rows.map { |row| row.inspect }.join("\n")
  end

  def ==(other)
    @rows == other.instance_variable_get(:@rows)
  end
end

# Usage:
m1 = Matrix.new([[1, 2], [3, 4]])
m2 = Matrix.new([[5, 6], [7, 8]])

puts m1 + m2
# [6, 8]
# [10, 12]

puts m1 * m2
# [19, 22]
# [43, 50]

puts m1.transpose
# [1, 3]
# [2, 4]
```

### Exercise 2

```ruby
# histogram — bucket numbers and print a bar chart
# Usage: histogram([2, 5, 7, 1, 9, 3, 6, 4, 8, 2], buckets: 5)

def histogram(numbers, buckets: 10, width: 40)
  return puts "No data" if numbers.empty?

  min    = numbers.min
  max    = numbers.max
  range  = (max - min).to_f
  range  = 1.0 if range == 0   # avoid division by zero

  bucket_size = range / buckets

  # Group numbers into buckets
  counts = Array.new(buckets, 0)
  numbers.each do |n|
    idx = [(( n - min) / bucket_size).floor, buckets - 1].min
    counts[idx] += 1
  end

  max_count = counts.max.to_f
  bar_width = width

  puts "Histogram (#{numbers.length} values, #{buckets} buckets):"
  puts "-" * (bar_width + 20)

  counts.each_with_index do |count, i|
    lower = (min + i * bucket_size).round(2)
    upper = (min + (i + 1) * bucket_size).round(2)
    bar   = "█" * (count * bar_width / max_count).round
    label = "[#{lower.to_s.rjust(6)}, #{upper.to_s.rjust(6)})"
    puts "#{label} #{bar} #{count}"
  end
end

# Usage:
data = Array.new(100) { rand(1..100) }
histogram(data, buckets: 10)

histogram([1, 1, 2, 3, 3, 3, 4, 4, 5], buckets: 5)
# Histogram (9 values, 5 buckets):
# [   1.0,    1.8) ██████████████████████ 2
# [   1.8,    2.6) ███████████ 1
# [   2.6,    3.4) ████████████████████████████████ 3
# [   3.4,    4.2) ██████████████████████ 2
# [   4.2,    5.0) ███████████ 1
```

### Exercise 3

```ruby
# deep_flatten — without using .flatten

def deep_flatten(arr)
  arr.each_with_object([]) do |element, result|
    if element.is_a?(Array)
      result.concat(deep_flatten(element))   # recurse
    else
      result << element
    end
  end
end

# Tests:
deep_flatten([1, [2, 3], [4, [5, [6, 7]]]])
# => [1, 2, 3, 4, 5, 6, 7]

deep_flatten([[[[1]]], [2, [3, [4]]]])
# => [1, 2, 3, 4]

deep_flatten([1, 2, 3])
# => [1, 2, 3]

# Alternative using Enumerator:
def deep_flatten_enum(arr)
  Enumerator.new do |y|
    arr.each do |el|
      if el.is_a?(Array)
        deep_flatten_enum(el).each { |x| y << x }
      else
        y << el
      end
    end
  end.to_a
end
```

### Exercise 4

```ruby
# Priority queue — array sorted by priority (lower number = higher priority)

class PriorityQueue
  Item = Struct.new(:priority, :value)

  def initialize
    @items = []
  end

  # Insert with priority (lower number = higher priority)
  def enqueue(value, priority:)
    @items << Item.new(priority, value)
    @items.sort_by!(&:priority)   # keep sorted
    self
  end

  # Remove and return highest-priority item (lowest priority number)
  def dequeue
    raise "Queue is empty" if empty?
    @items.shift.value
  end

  def peek
    raise "Queue is empty" if empty?
    @items.first.value
  end

  def size
    @items.size
  end

  def empty?
    @items.empty?
  end

  def to_s
    @items.map { |i| "#{i.priority}:#{i.value}" }.join(", ")
  end
end

# Usage:
pq = PriorityQueue.new
pq.enqueue("low priority task",    priority: 10)
pq.enqueue("urgent task",          priority: 1)
pq.enqueue("medium priority task", priority: 5)
pq.enqueue("critical task",        priority: 0)

puts pq          # => 0:critical task, 1:urgent task, 5:medium priority task, 10:low priority task

pq.dequeue       # => "critical task"
pq.dequeue       # => "urgent task"
pq.peek          # => "medium priority task"
puts pq.size     # => 2
```
