# Chapter 2 — Strings, Numbers, Collections

Chapter 1 handled one input at a time. This chapter is where the data gets wider: a whole file of colors, a whole CSV of sales, a whole page of text. Three programs — `histogram`, `csv_stats`, `wordfreq` — walk you through the moves you'll use in nearly every Ruby program: break text apart, count things, turn a pile of rows into one answer.

Read with the three programs in mind. You don't need to memorize every method. You need to recognise the *shapes*: transform each, keep some, count, sort, format.

## First build: histogram.rb

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

Five new things, in the order they appear.

### `File.readlines(..., chomp: true)`

```ruby
File.readlines("colors.txt")             # ["red\n", "blue\n", "red\n", ...]
File.readlines("colors.txt", chomp: true) # ["red", "blue", "red", ...]
```

Reads every line of the file into an array of strings. `chomp: true` strips the trailing newlines so `"red\n"` becomes `"red"`. Use this for small files. For files that might be huge, use `File.foreach` (Chapter 7) which streams line by line.

### `.tally` — counting in one call

```ruby
["red", "blue", "red"].tally   # => {"red" => 2, "blue" => 1}
```

Turn an array into a hash of value → count. Counting is so common it gets its own method. You'll reach for `tally` in all three programs.

### `.sort_by { ... }` with a negative key

```ruby
counts.sort_by { |_value, count| -count }
```

`sort_by` sorts by whatever the block returns. Ruby sorts ascending by default, so negating the count gives you *descending*. The underscore on `_value` is a convention for "I know I'm not using this" — silences the unused-variable warning.

### `"#" * count` — string multiplication

```ruby
"#" * 3   # => "###"
"-" * 20  # => "--------------------"
```

Multiplying a string by an integer repeats it. This is how the bars in the histogram get drawn.

### `.ljust(n)` — pad a string to a width

```ruby
"red".ljust(15)     # => "red            "
"yellow".ljust(15)  # => "yellow         "
```

Left-justify the string in a 15-character field, padding with spaces. The result is that the bars in the histogram line up in a neat column regardless of how long each value is. `rjust` is the right-justifying cousin — you'll meet it in `wordfreq.rb`.

(File: `examples/histogram.rb`. Test data: `examples/colors.txt`.)

## Second build: csv_stats.rb

Read a CSV with headers, find the numeric columns, print count / sum / mean / min / max for each.

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

Four new things.

### `require "csv"`

```ruby
require "csv"
```

Ruby's *standard library* is a big pile of modules that ship with Ruby but aren't loaded automatically. `require` pulls one in. `csv` is among the most useful — it handles quoting, escaping, and header rows so you don't write that yourself. Chapter 7 uses the same mechanism to pull in `json`, `net/http`, `set`, and friends.

### `CSV.read(filename, headers: true)`

```ruby
rows = CSV.read("sales.csv", headers: true)
rows.headers              # => ["date", "product", "amount"]
rows.first["product"]     # => "apple"
rows.map { |row| row["amount"] }
```

Parses the file. `headers: true` makes each row act like a hash keyed by column name — so you can write `row["product"]` instead of counting columns. Without `headers: true` you get plain arrays and have to remember column positions.

### `.map` and `.filter_map`

```ruby
[1, 2, 3, 4].map     { |n| n * 2 }                   # => [2, 4, 6, 8]
["3", "x", "5"].filter_map { |s| Integer(s, exception: false) }  # => [3, 5]
```

`map` transforms every element into a new array of the same length. `filter_map` does `map` and `select` in one pass: run the block, keep the truthy results, drop the `nil`s. `csv_stats` uses `filter_map` to convert the string cells to Floats and silently drop the non-numeric ones.

### `Float(v, exception: false)`

```ruby
Float("3.50")                      # => 3.5
Float("apple")                     # raises ArgumentError
Float("apple", exception: false)   # => nil
"apple".to_f                       # => 0.0     (silent — usually not what you want)
```

`Float(v, exception: false)` parses if it can, returns `nil` if it can't. Compare with `"apple".to_f` which silently returns `0.0` — that's how you accidentally compute that your average sale was `$0.47` when half your "amounts" were actually product names. The explicit `nil` signal is what makes `filter_map` work cleanly.

(File: `examples/csv_stats.rb`. Test data: `examples/sales.csv`.)

## Third build: wordfreq.rb

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

Four new things.

### `File.read(...).downcase`

```ruby
File.read("quote.txt")          # one giant string
File.read("quote.txt").downcase # lowercased
```

`File.read` slurps the whole file into a single string. Fine for small texts; use `foreach` (Ch 7) once files get large. Chaining `.downcase` afterwards folds case so `"The"` and `"the"` count as the same word.

### `.scan(regex)` — pull out every match

```ruby
"hello 42 world 99".scan(/\d+/)   # => ["42", "99"]
"Hello, world!".downcase.scan(/[a-z]+/)  # => ["hello", "world"]
```

`.scan(regex)` returns every substring that matches the pattern. `[a-z]+` means "one or more lowercase letters in a row". Punctuation and whitespace don't match, so they drop out. That single line is doing the work of a tokenizer.

### Composite sort keys: `[-count, word]`

```ruby
words.tally.sort_by { |word, count| [-count, word] }
```

Ruby compares arrays element by element. So sorting by `[-count, word]` means: "primary key is `-count` (highest count first), secondary key is `word` (alphabetical when counts tie)". Without the second key, tied words would come out in unpredictable order.

This trick is worth memorizing. It shows up anywhere you want stable multi-level sorting.

### `.rjust(n)`

```ruby
"3".rjust(6)    # => "     3"
"123".rjust(6)  # => "   123"
```

Right-justify in a 6-character field. The histogram used `.ljust` for left-alignment; `.rjust` is the mirror. Numbers usually want right-justification so the digits line up.

The `-n N` argument handling is crude — `ARGV.shift` peels arguments off the front one at a time. Chapter 4 shows cleaner ways with blocks. For now, this works.

(File: `examples/wordfreq.rb`. Test data: `examples/quote.txt`.)

## More tools you'll need

The three programs introduced the essentials. The rest of this chapter's vocabulary comes up often enough that you should recognise it on sight.

### Strings

```ruby
s = "Hello, World!"

s.length            # => 13
s.upcase            # => "HELLO, WORLD!"
s.reverse           # => "!dlroW ,olleH"
s.split(",")        # => ["Hello", " World!"]
s.split             # => ["Hello,", "World!"]  (default: whitespace)
s.chars             # => ["H", "e", "l", "l", "o", ...]
s.gsub("l", "L")    # => "HeLLo, WorLd!"
s.strip             # => "Hello, World!"        (trim whitespace)
s.tr("aeiou", "*")  # => "H*ll*, W*rld!"        (one-for-one translate)
s[0]                # => "H"
s[0, 5]             # => "Hello"                (start, length)
s[0..4]             # => "Hello"                (range)
s[-1]               # => "!"                    (negative from the end)
s.include?("World") # => true
s.start_with?("He") # => true
```

Strings are mutable by default — `s << " more"` modifies `s` in place. Most methods you'll use (`upcase`, `strip`, `gsub`) return *new* strings and leave the original alone. The mutating variants have a `!` suffix (`upcase!`, `strip!`, `gsub!`). Use the non-mutating form by default.

### Numbers and ranges

```ruby
10 + 3     # => 13
10 / 3     # => 3         # integer division truncates
10 / 3.0   # => 3.333...  # float division
10 % 3     # => 1
2 ** 10    # => 1024

3.14.round       # => 3
3.14.round(1)    # => 3.1
3.14.ceil        # => 4
(-3.14).abs      # => 3.14
```

The integer-division trap bites everyone once. `10 / 3` gives `3`, not `3.333`. To get a float, one operand must be a float: `10.0 / 3` or `10 / 3.0`.

```ruby
(1..5).to_a          # => [1, 2, 3, 4, 5]   inclusive
(1...5).to_a         # => [1, 2, 3, 4]      exclusive of end
(1..5).sum           # => 15
(1..100).step(10).to_a  # => [1, 11, 21, ..., 91]
```

Ranges work in `case/when` and in array slicing (`s[0..4]`).

### Arrays

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
nums.reverse
nums.sum          # => 31
nums.min          # => 1
nums.max          # => 9
nums.count(1)     # => 2
nums.include?(5)  # => true

[1, 2, 3].push(4)    # add to end (alias: <<)
[1, 2, 3].pop        # remove from end
[1, 2, 3].shift      # remove from start
[1, 2, 3].unshift(0) # add to start
```

Three more iteration patterns you'll write constantly:

```ruby
[1, 2, 3].map    { |n| n * 2 }         # => [2, 4, 6]    transform
[1, 2, 3, 4].select { |n| n.even? }    # => [2, 4]       keep matching
[1, 2, 3, 4].reject { |n| n.even? }    # => [1, 3]       drop matching
[1, 2, 3].sum    { |n| n ** 2 }        # => 14           transform-then-sum
```

`{ |x| ... }` is the one-line block form; multi-line uses `do |x| ... end`. Both are blocks; pick by length, not meaning.

### Hashes

```ruby
h = { "a" => 1, "b" => 2, "c" => 3 }

h["a"]            # => 1
h.keys            # => ["a", "b", "c"]
h.values          # => [1, 2, 3]
h["d"] = 4        # add a key
h.delete("a")     # remove a key
h.include?("b")   # => true
```

Prefer symbol keys. They're cheaper and Ruby has shorthand syntax for them:

```ruby
person = { name: "Yosia", age: 30 }
person[:name]     # => "Yosia"

# Old long form (you'll still see it):
person = { :name => "Yosia", :age => 30 }
```

Use `name:` style by default. Fall back to `"name"` keys only when the key has spaces or comes from external data (JSON, HTTP requests).

Iterate with two parameters:

```ruby
person.each do |key, value|
  puts "#{key}: #{value}"
end
```

`.fetch` is `[]` with a default or a failure mode:

```ruby
person[:foo]            # => nil       # silent
person.fetch(:foo)      # => raises KeyError
person.fetch(:foo, "?") # => "?"       # default
```

Use `.fetch` when a missing key is a bug, not an acceptable state.

### Sets

```ruby
require "set"

seen = Set.new
%w[apple banana apple cherry].each { |w| seen << w }
seen.include?("apple")   # => true
```

A `Set` is an array that keeps uniqueness and answers `include?` in constant time. Reach for it when you have a "have I seen this?" question over a large collection — `Array#include?` scans linearly; `Set#include?` doesn't.

### `&:method` — the block shorthand

```ruby
["hello", "world"].map(&:upcase)       # => ["HELLO", "WORLD"]
[1, 2, 3].map(&:to_s)                  # => ["1", "2", "3"]
people.map(&:name)                     # => names
```

`&:upcase` is shorthand for `{ |x| x.upcase }`. One of the most common Ruby idioms. You'll see it everywhere. The trick works whenever the block just calls one no-argument method on its input.

## Common pitfalls

**Integer division.** `10 / 3` is `3`, not `3.333...`. Convert one operand: `10.0 / 3` or `count.to_f / total`. The bug usually surfaces as a percentage that's always `0`.

**String mutability.** `s.upcase` returns a new string; `s.upcase!` mutates in place and returns `nil` if nothing changed. Assigning the result of a `!` method back into the variable can leave you with `nil`:

```ruby
s = "ABC"
s = s.upcase!   # => nil  (already uppercase; bang returned nil; s is now nil)
```

**Mixing symbol and string keys.** `{ name: "Yosia" }[:name]` works; `{ name: "Yosia" }["name"]` returns `nil`. Pick one shape per hash. JSON parsing returns string keys by default; symbol-keyed code that meets a JSON hash will read `nil` everywhere.

**`[]` returns nil silently.** `arr[100]` and `h[:missing]` both return `nil` rather than raising. The error surfaces three method calls later as `NoMethodError: undefined method 'x' for nil`. Use `arr.fetch(i)` / `h.fetch(k)` when a missing value is a bug.

## What you learned

| Concept | Key point |
|---|---|
| `s.split` / `s.chars` | break a string into pieces |
| `s.upcase` / `s.downcase` | case shifts |
| `s.gsub(a, b)` | replace all occurrences |
| `s.scan(/regex/)` | extract all matches as an array |
| `"#" * n` / `s.ljust(n)` / `s.rjust(n)` | padding and repetition |
| `10 / 3` vs `10 / 3.0` | integer vs float division |
| `(1..10)` / `(1...10)` | inclusive vs exclusive range |
| `arr.sort` / `.sort_by` | sort with a key |
| `arr.map { ... }` | transform each element |
| `arr.select` / `.reject` | keep / drop elements |
| `arr.filter_map { ... }` | filter and map in one pass |
| `arr.tally` | count occurrences |
| `{ name: "x" }` | symbol-keyed hash |
| `h.fetch(k, default)` | safe lookup with fallback |
| `&:method` | block shorthand for "call this method" |
| `require "csv"` | load a stdlib library |
| `CSV.read(file, headers: true)` | parse CSV with column names |
| `Float(v, exception: false)` | parse if numeric, else `nil` |
| `[-count, word]` sort keys | multi-level sort, first key descending |

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
