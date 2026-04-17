# Chapter 2 — Strings, Numbers, Collections

Chapter 1 handled one input at a time. This chapter is where the data gets wider: a whole file of colors, a whole CSV of sales, a whole page of text. The three programs are a `histogram`, a `csv_stats` summarizer, and a `wordfreq` counter.

You do not need to memorize every method below. Treat the early sections as a toolbelt, not a reference manual. Read them with the three programs in mind. Which methods help break text apart? Which ones count? Which ones turn a pile of rows into one answer? That is the thread of the chapter.

Most non-trivial Ruby code is at heart string transformation, hash counting, and array iteration. The methods in this chapter appear in nearly every Ruby program you'll write.

## New Ruby ideas you'll meet in this chapter

- **String methods** — `downcase`, `upcase`, `strip`, `split`, `gsub`, `scan`. Each returns a new string (or array); originals stay unchanged.
- **Regex (regular expression)** — a tiny pattern language for matching text. `/[a-z]+/` means "one or more lowercase letters in a row".
- **Array** — ordered list of values: `[1, 2, 3]`. Index with `arr[0]`, grow with `<<`.
- **Hash** — a map from keys to values: `{ name: "Yosia", age: 30 }`. Ruby's universal lookup table.
- **`.tally`** — counts how many times each element appears in an array. `["a","b","a"].tally` → `{"a"=>2, "b"=>1}`.
- **`.sort_by { |x| key }`** — sort by whatever the block returns. Sorting by `[-count, word]` means "highest count first, alphabetical for ties".
- **`.filter_map`** — `map` + `compact` in one pass. Run the block, keep truthy results, drop `nil`s.
- **`ljust(n)` / `rjust(n)`** — pad a string to `n` characters so columns in output line up neatly.

## The toolbelt starts with strings

You've used strings; look closer.

```ruby
s = "Hello, World!"

s.length            # => 13
s.upcase            # => "HELLO, WORLD!"
s.downcase          # => "hello, world!"
s.reverse           # => "!dlroW ,olleH"
s.split(",")        # => ["Hello", " World!"]
s.split             # => ["Hello,", "World!"]   # default: split on whitespace
s.chars             # => ["H", "e", "l", "l", "o", ...]
s.gsub("l", "L")    # => "HeLLo, WorLd!"
s.strip             # => "Hello, World!"        # trim leading/trailing whitespace
s.tr("aeiou", "*")  # => "H*ll*, W*rld!"        # translate chars one-for-one
s[0]                # => "H"
s[0, 5]             # => "Hello"                # substring (start, length)
s[0..4]             # => "Hello"                # substring (range)
s[-1]               # => "!"                    # negative index from the end
s.include?("World") # => true
s.start_with?("He") # => true
```

Strings are *mutable* by default — `s << " more"` modifies `s` in place. Most of the time you'll call methods that return new strings (like `upcase`) and ignore mutability. When mutability bites you, the cause is usually a method modifying a string passed as an argument.

## Numbers

Two kinds: integers (`1`, `42`, `-7`) and floats (`1.0`, `3.14`). Ruby auto-promotes to float when needed.

```ruby
10 + 3      # => 13
10 / 3      # => 3        # integer division — truncates
10 / 3.0    # => 3.333... # float division
10 % 3      # => 1        # modulo
2 ** 10     # => 1024     # exponent

3.14.round       # => 3
3.14.round(1)    # => 3.1
3.14.ceil        # => 4
3.14.floor       # => 3
(-3.14).abs      # => 3.14
```

The integer-division trap bites everyone once. `10 / 3` gives `3`, not `3.333...`. To get the float result, one operand must be a float: `10.0 / 3` or `10 / 3.0`.

Ranges express "all numbers from X to Y":

```ruby
(1..5).to_a          # => [1, 2, 3, 4, 5]    # inclusive
(1...5).to_a         # => [1, 2, 3, 4]       # exclusive of end
(1..5).sum           # => 15
(1..100).step(10).to_a  # => [1, 11, 21, ..., 91]
```

Ranges work in `case/when` (Chapter 1) and in array slicing (`s[0..4]`).

## Arrays

Ordered collections. The values can be of mixed types.

```ruby
nums = [3, 1, 4, 1, 5, 9, 2, 6]

nums.length       # => 8
nums.first        # => 3
nums.last         # => 6
nums[0]           # => 3
nums[-1]          # => 6
nums[1..3]        # => [1, 4, 1]
nums.sort         # => [1, 1, 2, 3, 4, 5, 6, 9]
nums.uniq         # => [3, 1, 4, 5, 9, 2, 6]
nums.reverse      # => [6, 2, 9, 5, 1, 4, 1, 3]
nums.sum          # => 31
nums.min          # => 1
nums.max          # => 9
nums.count(1)     # => 2
nums.include?(5)  # => true

[1, 2, 3].push(4)    # => [1, 2, 3, 4]    # add to end (alias: <<)
[1, 2, 3].pop        # => 3                # remove from end
[1, 2, 3].shift      # => 1                # remove from start
[1, 2, 3].unshift(0) # => [0, 1, 2, 3]    # add to start
```

Iteration with a block — you saw this in Chapter 1's `tiny_processor`:

```ruby
nums.each do |n|
  puts n
end
```

Three more iteration patterns you'll write constantly:

```ruby
[1, 2, 3].map { |n| n * 2 }            # => [2, 4, 6]      # transform each → new array
[1, 2, 3, 4].select { |n| n.even? }    # => [2, 4]         # filter
[1, 2, 3, 4].reject { |n| n.even? }    # => [1, 3]         # filter, opposite
[1, 2, 3].sum { |n| n ** 2 }           # => 14             # transform-then-sum
```

`{ |x| ... }` is a one-line block; multi-line uses `do |x| ... end`. Both are blocks. Pick by length, not by meaning.

## Hashes

Key-value pairs. Like a lookup table.

```ruby
h = { "a" => 1, "b" => 2, "c" => 3 }

h["a"]            # => 1
h.length          # => 3
h.keys            # => ["a", "b", "c"]
h.values          # => [1, 2, 3]
h["d"] = 4        # add a key
h.delete("a")     # remove a key
h.include?("b")   # => true
h.empty?          # => false
```

Symbols (e.g., `:name`, `:age`) make better keys than strings. They're cheaper (interned — same symbol is always the same object) and Ruby has shorthand syntax for symbol-keyed hashes:

```ruby
person = { name: "Yosia", age: 30 }
person[:name]     # => "Yosia"

# Equivalent (older syntax — you'll see it in old code):
person = { :name => "Yosia", :age => 30 }
```

Use `name:`-style keys by default. Use `"name"`-style only when the key has spaces or comes from external data (JSON, an HTTP request).

Iterate hashes with two block parameters:

```ruby
person.each do |key, value|
  puts "#{key}: #{value}"
end
# => name: Yosia
# => age: 30
```

`fetch` is `[]` with a default:

```ruby
person[:foo]            # => nil       # no key — silently nil
person.fetch(:foo)      # => raises KeyError
person.fetch(:foo, "?") # => "?"       # default
```

## Sets

A `Set` is an array that enforces uniqueness and answers `include?` in constant time. Reach for it when you have a "have I seen this?" question over a large collection — `array.include?` scans linearly; `set.include?` doesn't.

```ruby
require "set"

seen = Set.new
%w[apple banana apple cherry].each { |w| seen << w }
seen                # => #<Set: {"apple", "banana", "cherry"}>
seen.include?("apple")   # => true
```

## tally — the most useful counting idiom

Counting how often each value appears is so common it has its own method:

```ruby
words = ["apple", "banana", "apple", "cherry", "apple", "banana"]
words.tally           # => {"apple" => 3, "banana" => 2, "cherry" => 1}

[1, 2, 2, 3, 3, 3].tally  # => {1 => 1, 2 => 2, 3 => 3}
```

You'll use `tally` in all three programs in this chapter.

## histogram.rb

Read a file (one value per line), count occurrences, print a horizontal bar chart sorted from most to least common.

```ruby
# histogram.rb — print a horizontal bar chart of value frequencies
# Usage: ruby histogram.rb <file>

filename = ARGV[0]
counts = File.readlines(filename, chomp: true).tally

counts.sort_by { |_value, count| -count }.each do |value, count|
  bar = "#" * count
  puts "#{value.ljust(15)} #{bar} #{count}"
end
```

Test data `colors.txt`:

```
red
blue
red
green
blue
red
yellow
```

Run:

```
$ ruby histogram.rb colors.txt
red             ### 3
blue            ## 2
green           # 1
yellow          # 1
```

Three new things.

`File.readlines(filename, chomp: true)` reads the entire file into an array of strings, one per line, with the trailing `\n` already stripped (because of `chomp: true`).

`tally` builds a hash `value → count`.

`sort_by { |_value, count| -count }` sorts by count descending. Ruby sorts ascending by default; negating flips the order. The `_value` is conventional for "I don't care about this parameter" — Ruby's underscore prefix silences the unused-variable warning.

`"text".ljust(15)` left-justifies in a 15-char field, padding with spaces. `"#" * count` repeats the character `count` times.

(File: `examples/histogram.rb`. Test data: `examples/colors.txt`.)

## csv_stats.rb

Read a CSV with headers, find the numeric columns, print count/sum/mean/min/max for each.

```ruby
# csv_stats.rb — basic stats for numeric columns of a CSV
# Usage: ruby csv_stats.rb <file>

require "csv"

filename = ARGV[0]
rows = CSV.read(filename, headers: true)

rows.headers.each do |column|
  values  = rows.map { |row| row[column] }
  numbers = values.filter_map { |v| Float(v, exception: false) }
  next if numbers.empty?

  count = numbers.length
  sum   = numbers.sum
  mean  = sum / count
  min   = numbers.min
  max   = numbers.max

  puts "#{column}: count=#{count} sum=#{sum.round(2)} mean=#{mean.round(2)} min=#{min} max=#{max}"
end
```

Test data `sales.csv`:

```
date,product,amount
2026-01-01,apple,3.50
2026-01-02,banana,1.20
2026-01-03,apple,3.50
2026-01-04,cherry,8.00
```

Run:

```
$ ruby csv_stats.rb sales.csv
amount: count=4 sum=16.2 mean=4.05 min=1.2 max=8.0
```

What's new.

`require "csv"` loads the CSV library from Ruby's standard library. The standard library is everything that ships with Ruby; Chapter 7 covers more of it.

`CSV.read(filename, headers: true)` parses the file. `headers: true` makes each row act like a hash keyed by column name.

`rows.headers` returns the column names as an array of strings.

`Float(v, exception: false)` converts `v` to a Float, or returns `nil` if the value isn't numeric. Unlike `to_f` (which returns `0.0` for non-numeric strings), this gives us a true "is it a number?" signal.

`filter_map` is `select` and `map` in one pass — keep elements where the block returns a truthy value, transformed by the block. Here it both filters out non-numeric values (returns `nil`) and converts the survivors to Floats.

`map(&:method_name)` is shorthand for `map { |x| x.method_name }`. The `&:symbol` form is one of the most common Ruby idioms — you'll see it everywhere. We don't use it here because `Float(v, exception: false)` is a method *call*, not a method reference, but you'll meet `&:to_i`, `&:strip`, etc. constantly.

(File: `examples/csv_stats.rb`. Test data: `examples/sales.csv`.)

## wordfreq.rb

Read a text file, print the N most-frequent words.

```ruby
# wordfreq.rb — print the N most-frequent words in a text
# Usage: ruby wordfreq.rb [-n N] <file>

n = 10
if ARGV[0] == "-n"
  ARGV.shift
  n = ARGV.shift.to_i
end

filename = ARGV[0]
text = File.read(filename).downcase

words = text.scan(/[a-z]+/)

frequencies = words.tally.sort_by { |word, count| [-count, word] }

frequencies.first(n).each do |word, count|
  puts "#{count.to_s.rjust(6)}  #{word}"
end
```

Test data `quote.txt`:

```
The best programs are small, clear, and do exactly what they say.
That's true in C, in shell, and in Ruby.
```

Run:

```
$ ruby wordfreq.rb -n 5 quote.txt
     3  in
     2  and
     1  are
     1  best
     1  c
```

The sort key `[-count, word]` is a composite — Ruby compares arrays element by element, so this means "sort by `-count` first, then by `word` alphabetically when counts tie." Without the second sort key, ties between equal-count words would come out in an unpredictable order.

What's new.

`File.read(filename)` reads the whole file into a single string.

`.scan(/[a-z]+/)` extracts all matches of the regex. `[a-z]+` means "one or more lowercase letters." Since we already lowercased the text, this gives us all words and skips punctuation cleanly.

`.first(n)` returns the first `n` elements of an array.

`count.to_s.rjust(6)` right-justifies the count in a 6-character field.

The `-n N` option handling is crude — `ARGV.shift` to peel arguments off the front. Chapter 4 introduces nicer ways. For now, this works.

(File: `examples/wordfreq.rb`. Test data: `examples/quote.txt`.)

## Common pitfalls

**Integer division.** `10 / 3` is `3`, not `3.333...`. Convert one operand: `10.0 / 3` or `count.to_f / total`. The bug usually surfaces as a percentage that's always `0`.

**String mutability.** `s.upcase` returns a new string; `s.upcase!` mutates in place and returns `nil` if nothing changed. Assigning the result of a `!` method into a variable can leave you with `nil`.

```ruby
s = "ABC"
s = s.upcase!   # => nil   # already uppercase; bang returned nil; s is now nil
```

**Mixing symbol and string keys.** `{ name: "Yosia" }[:name]` works; `{ name: "Yosia" }["name"]` returns `nil`. Pick one shape per hash. JSON parsing returns string keys by default; symbol-keyed code that meets a JSON hash will read `nil` everywhere.

**`[]` returns nil silently.** `arr[100]` and `h[:missing]` both return `nil` rather than raising. The error surfaces three method calls later as `NoMethodError: undefined method 'x' for nil`. Use `arr.fetch(i)` / `h.fetch(k)` when a missing value is a bug, not a default.

## What you learned

| Concept | Key point |
|---|---|
| `s.split` / `s.chars` | break a string into pieces |
| `s.upcase` / `s.downcase` | case shifts |
| `s.gsub(a, b)` | replace all occurrences of `a` with `b` |
| `s.scan(/regex/)` | extract all matches as an array |
| `10 / 3` vs `10 / 3.0` | integer division vs float division |
| `(1..10)` / `(1...10)` | inclusive vs exclusive range |
| `arr.sort` / `.sort_by` | sort an array (with a key) |
| `arr.map { ... }` | transform each element → new array |
| `arr.select { ... }` | keep elements matching the block |
| `arr.filter_map { ... }` | filter and map in one pass |
| `arr.tally` | count occurrences → hash |
| `{ name: "x" }` | symbol-keyed hash |
| `h.fetch(k, default)` | safe lookup with fallback |
| `&:method` | block shorthand for "call this method" |
| `require "csv"` | load a stdlib library |
| `CSV.read(file, headers: true)` | parse CSV with column names |
| `Float(v, exception: false)` | parse if numeric, else `nil` |

## Going deeper

`Set` (`require "set"`) belongs in the same mental drawer as Array and Hash. Read its docs once.

`Comparable` is the mixin behind `<`, `>`, `between?`, `clamp`, `min`, `max`. Any class that defines `<=>` gets all of those for free — Chapter 5 shows how to use it on your own classes.

Real CSVs at scale (millions of rows) want `CSV.foreach(filename, headers: true)` instead of `CSV.read` — same shape, but streams a row at a time without loading the file into memory. The pattern (`read` for small files, `foreach` for big ones) repeats throughout Ruby's I/O.

## Exercises

1. **histogram from stdin**: extend `histogram.rb` to read from stdin when no filename is given. Test with `cat colors.txt | ruby exercises/1_histogram_stdin.rb`. Starter: `exercises/1_histogram_stdin.rb`.

2. **histogram with a width cap**: long bars overflow the terminal. Scale bars so the longest is at most 40 characters wide; print the scaled bar plus the actual count. Starter: `exercises/2_histogram_scaled.rb`.

3. **csv_stats with column selection**: extend `csv_stats.rb` to accept `--col name` flags, computing stats only for the named columns. `ruby csv_stats.rb sales.csv --col amount` prints just the `amount` row. Starter: `exercises/3_csv_stats_col.rb`.

4. **wordfreq with a stopword list**: extend `wordfreq.rb` to skip common words like "the", "and", "in", "of", "a", "to". The stopword list should be a constant array at the top of the file. Starter: `exercises/4_wordfreq_stopwords.rb`.

5. **median.rb**: read numbers from a file (one per line), print the median. (Median = middle value after sorting; for even-length lists, average of the two middle values.) Starter: `exercises/5_median.rb`.

6. **anagrams.rb**: read a word list (one word per line), print groups of anagrams. Words are anagrams if they contain the same letters. Hint: `word.chars.sort.join` is the same for all anagrams of a given letter set. `arr.group_by { ... }` returns a hash. Starter: `exercises/6_anagrams.rb`.
