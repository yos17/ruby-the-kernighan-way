# Chapter 3 — Control Flow and Iteration

This chapter is about decisions: which lines match, which values to keep, which path through the code should run next. The programs are a `grep` clone, an error counter, and a log summarizer. They all do the same two jobs over and over: choose and group.

Professional Ruby code reaches for an Enumerable method first and a `while` loop almost never. Once you can name the right method (`group_by`, `partition`, `chunk_while`, `each_with_object`), most data-shaping problems collapse into one line. The control-flow forms in the first half of the chapter matter because they feed the programs in the second half, not because you need to memorize a taxonomy of loops.

## if, unless, and the modifier forms

You've seen the basic `if`:

```ruby
if score > 90
  puts "great"
elsif score > 70
  puts "ok"
else
  puts "study more"
end
```

Two terser forms when there's only one branch:

```ruby
puts "great" if score > 90        # if-modifier
puts "you forgot" unless score    # unless-modifier (when score is nil/false)
```

`unless` is `if not`. Use it when the negation reads naturally. Don't use `unless` with `else` — `if/else` is clearer for two-way choices.

The ternary picks between two values:

```ruby
status = score > 60 ? "pass" : "fail"
```

For longer choices, use `if`/`else` as an expression. Ruby returns the value of the chosen branch:

```ruby
status = if score > 90
           "great"
         elsif score > 70
           "ok"
         else
           "study more"
         end
```

That's still one statement. Assigning the result of an `if` is normal Ruby, not a hack.

## case/when revisited

`case/when` does more than match strings:

```ruby
case x
when Integer then "an integer"
when String  then "a string"
when 1..10   then "small number"     # range
when /^err/  then "starts with err"  # regex
when nil     then "nothing"
else              "something else"
end
```

The match operator under the hood is `===`:

- `Integer === x` is true if `x` is an Integer
- `(1..10) === x` is true if `x` is in the range
- `/^err/ === "error"` is true if the regex matches

You don't usually invoke `===` directly — `case/when` does it for you.

## Pattern matching: case/in

Ruby 3 added a richer matching form: `case/in`. It looks like `case/when` but matches **shape** as well as value, and binds variables.

```ruby
shape = { type: "circle", radius: 5 }

case shape
in { type: "circle", radius: r }
  puts "circle with radius #{r}"
in { type: "rectangle", width: w, height: h }
  puts "#{w}x#{h} rectangle"
in { type: type }
  puts "unknown shape: #{type}"
end
# => circle with radius 5
```

The `in` patterns destructure data. `r` gets bound to the value of the `:radius` key. Pattern matching shows up properly in Chapter 6's metaprogramming and gets used heavily for the JSON walker later. For now, know that `case/in` exists and is the modern way to match structured data.

## Loops

Three forms.

```ruby
# while: repeat as long as condition is true
i = 0
while i < 3
  puts i
  i += 1
end

# until: repeat as long as condition is false
balance = 100
until balance <= 0
  balance -= 10
end

# loop: forever (you must break)
loop do
  print "command> "
  cmd = gets&.chomp
  break if cmd == "quit" || cmd.nil?
  puts "got: #{cmd}"
end
```

`gets&.chomp` — the `&.` is the *safe-navigation operator*. If `gets` returns `nil` (end of input), `&.chomp` returns `nil` instead of crashing. Without it, `gets.chomp` blows up on EOF.

Ruby has more idiomatic counted loops:

```ruby
3.times { |i| puts i }                # 0, 1, 2
5.upto(8) { |i| puts i }              # 5, 6, 7, 8
8.downto(5) { |i| puts i }            # 8, 7, 6, 5
1.step(10, 2) { |i| puts i }          # 1, 3, 5, 7, 9
```

You'll rarely write `while` loops in idiomatic Ruby — Enumerable methods (next section) cover almost every case.

## break, next, redo

Inside a loop or block:

```ruby
[1, 2, 3, 4, 5].each do |n|
  next if n.even?     # skip this iteration
  break if n > 3      # exit the loop
  puts n
end
# => 1, 3
```

`break` can return a value:

```ruby
result = [1, 2, 3].each do |n|
  break "found #{n}" if n == 2
end
result   # => "found 2"
```

## Debugging loops

Loops are where beginners most often lose the thread. The program is correct for the first two iterations, wrong on the third, and by the time you print one variable you no longer know which pass you are looking at. Stop inside the loop instead.

With the built-in debugger:

```ruby
require "debug"

[10, 20, 30].each_with_index do |value, i|
  binding.break if i == 1
  puts "#{i}: #{value}"
end
```

When it stops, inspect the live state:

```text
info          # local variables
p i           # => 1
p value       # => 20
next          # run the next line in this frame
continue      # resume the rest of the program
```

If you prefer Pry:

```ruby
require "pry"

[10, 20, 30].each_with_index do |value, i|
  binding.pry if i == 1
  puts "#{i}: #{value}"
end
```

Inside Pry, `i`, `value`, and anything else in scope are available immediately. If you also installed `pry-byebug`, you get `step`, `next`, `finish`, and `continue` there too.

The useful habit is this: stop on the suspicious iteration, not after the loop has already run past the bug.

## Enumerable — the workhorse

Most iteration uses Enumerable methods on arrays and hashes. You met `each`, `map`, `select`, `reject`, `tally`, `sort_by` in Chapter 2. A few more:

```ruby
# reduce / inject — combine all elements into one value
[1, 2, 3, 4].reduce(0) { |sum, n| sum + n }   # => 10
[1, 2, 3, 4].reduce(:+)                       # => 10  (shorthand: call this method)
[1, 2, 3, 4].reduce(1, :*)                    # => 24  (initial value + method symbol)

# each_with_index — index alongside element
["a", "b", "c"].each_with_index do |val, i|
  puts "#{i}: #{val}"
end

# each_with_object — accumulate into a starting value
words = ["apple", "banana", "cherry"]
words.each_with_object({}) { |w, h| h[w[0]] = w }
# => {"a" => "apple", "b" => "banana", "c" => "cherry"}

# group_by — split into a hash by the block's return value
[1, 2, 3, 4, 5].group_by { |n| n.even? ? :even : :odd }
# => {odd: [1, 3, 5], even: [2, 4]}

# partition — split into [matches, non-matches]
[1, 2, 3, 4, 5].partition(&:even?)
# => [[2, 4], [1, 3, 5]]

# chunk_while — group consecutive runs by an adjacency rule
[1, 2, 3, 5, 6, 8].chunk_while { |a, b| b - a == 1 }.to_a
# => [[1, 2, 3], [5, 6], [8]]

# zip — pair up parallel arrays
[1, 2, 3].zip([:a, :b, :c])    # => [[1, :a], [2, :b], [3, :c]]

# any? / all? / none? / count
[1, 2, 3].any? { |n| n > 2 }   # => true
[1, 2, 3].all? { |n| n > 0 }   # => true
[1, 2, 3].count(&:odd?)        # => 2
```

The pattern is: think about what you want, then find the Enumerable method that says it. A `while` loop with a counter is almost always the wrong tool.

## grep.rb

A real grep: pattern + filenames + flags.

```ruby
# grep.rb — find lines matching a regex pattern
# Usage: ruby grep.rb [-i] [-n] [-v] [-c] PATTERN [FILE ...]
#   -i  case-insensitive
#   -n  show line numbers
#   -v  invert (show non-matching lines)
#   -c  count only (print number of matches per file)

flags = { i: false, n: false, v: false, c: false }

while ARGV.first&.start_with?("-")
  arg = ARGV.shift
  arg[1..].each_char { |c| flags[c.to_sym] = true }
end

pattern_str = ARGV.shift
abort "usage: grep.rb [-i] [-n] [-v] [-c] PATTERN [FILE ...]" if pattern_str.nil?

pattern = Regexp.new(pattern_str, flags[:i] ? Regexp::IGNORECASE : 0)
sources = ARGV.empty? ? [["(stdin)", STDIN]] : ARGV.map { |f| [f, File.open(f)] }

sources.each do |name, io|
  matches = 0
  io.each_line.with_index(1) do |line, lineno|
    matched = pattern.match?(line)
    next unless matched ^ flags[:v]
    matches += 1
    next if flags[:c]
    parts = []
    parts << name if sources.length > 1
    parts << lineno.to_s if flags[:n]
    print parts.empty? ? line : "#{parts.join(":")}:#{line}"
  end
  puts "#{name}:#{matches}" if flags[:c]
ensure
  io.close if io != STDIN
end
```

Run:

```
$ printf "one\ntwo\nthree\nfour\n" > demo.txt
$ ruby grep.rb -n -i 'th' demo.txt
3:three
$ ruby grep.rb -v 'e' demo.txt
two
four
$ ruby grep.rb -c 'e' demo.txt
demo.txt:2
```

What's new.

`Regexp.new(str, flags)` builds a regex from a string with optional flags. `Regexp::IGNORECASE` makes matches case-insensitive.

`pattern.match?(line)` returns `true`/`false` without building a `MatchData` object — faster and what you want when you don't need the matches.

`matched ^ flags[:v]` is XOR: true when exactly one of the two is true. With `-v` set, only non-matching lines pass; otherwise only matching lines do.

`io.each_line.with_index(1)` iterates lines starting line numbers from 1.

`arg[1..].each_char { |c| flags[c.to_sym] = true }` lets you bundle short flags: `-in` is the same as `-i -n`. `arg[1..]` is everything after the leading `-`.

`ensure` runs whether the block succeeds or raises — used here to close file handles. Chapter 7 covers exceptions properly.

(File: `examples/grep.rb`. Test data: `examples/demo.txt`.)

## top_errors.rb

A log analyzer: find the most common ERROR-level messages in a log file.

```ruby
# top_errors.rb — print the most common ERROR messages in a log
# Usage: ruby top_errors.rb [-n N] <logfile>

n = 5
if ARGV[0] == "-n"
  ARGV.shift
  n = ARGV.shift.to_i
end

filename = ARGV[0]

errors = File.foreach(filename)
             .filter_map { |line| line[/\bERROR\b\s+(.*)$/, 1]&.strip }

errors.tally
      .sort_by { |msg, count| [-count, msg] }
      .first(n)
      .each { |msg, count| puts "#{count.to_s.rjust(4)}  #{msg}" }
```

Test data `app.log`:

```
2026-04-17 10:00:01 INFO  startup complete
2026-04-17 10:00:05 ERROR connection refused
2026-04-17 10:00:07 WARN  slow query 350ms
2026-04-17 10:00:10 ERROR connection refused
2026-04-17 10:00:12 ERROR timeout reading socket
2026-04-17 10:00:15 INFO  request handled
2026-04-17 10:00:20 ERROR connection refused
2026-04-17 10:00:25 ERROR timeout reading socket
```

Run:

```
$ ruby top_errors.rb -n 3 app.log
   3  connection refused
   2  timeout reading socket
```

What's new.

`File.foreach(filename)` returns a lazy enumerator — lines are read one at a time as the chain consumes them, not all at once into memory. For a 100MB log, that's the difference between consuming 100MB of RAM and consuming a few KB.

`.filter_map { ... }` (from Chapter 2) does select-and-map in one pass. The block returns the captured error message text (or `nil` for non-matching lines); `filter_map` keeps only the truthy returns.

`line[/\bERROR\b\s+(.*)$/, 1]` is regex matching with a capture group. `\b` is a word boundary. `(.*)` captures everything after `ERROR ` to end of line. The `1` returns the first capture group's text, or `nil` if no match.

`&.strip` calls `strip` only if the value isn't `nil` (safe-navigation again).

The `[-count, msg]` composite sort key (from Chapter 2) keeps the output deterministic when counts tie.

(File: `examples/top_errors.rb`. Test data: `examples/app.log`.)

## log_summary.rb

A different angle on the same log: group lines by hour and count each severity level.

```ruby
# log_summary.rb — count log entries per hour, broken down by level
# Usage: ruby log_summary.rb <logfile>

filename = ARGV[0]

entries = File.foreach(filename)
              .filter_map { |line| line.match(/^(\d{4}-\d{2}-\d{2} \d{2}):\d{2}:\d{2}\s+(\w+)/) }

by_hour = entries.group_by { |m| m[1] }

by_hour.sort.each do |hour, ms|
  level_counts = ms.map { |m| m[2] }.tally
  parts = level_counts.sort.map { |level, count| "#{level}=#{count}" }
  puts "#{hour}  #{parts.join(' ')}"
end
```

Run:

```
$ ruby log_summary.rb app.log
2026-04-17 10  ERROR=5 INFO=2 WARN=1
```

What's new.

`line.match(/.../)` returns a `MatchData` object (with capture groups accessible via `m[1]`, `m[2]`...) or `nil`. Combined with `filter_map`, this filters out lines that don't match.

`group_by { |m| m[1] }` groups MatchData objects by the first capture (the hour stem like `2026-04-17 10`).

`sort` on a hash returns an array of `[key, value]` pairs sorted by key. Iterating that gives you sorted-key-order traversal.

Compose this with `top_errors.rb` and you have the start of a real log analytics tool — Chapter 8's halfway capstone uses both.

(File: `examples/log_summary.rb`.)

## Common pitfalls

**`case/in` falls through to `NoMatchingPatternError`.** Unlike `case/when`, an unmatched `case/in` raises. Add an `else` branch for any value you don't intend to handle:

```ruby
case shape
in { type: "circle", radius: r } then "circle #{r}"
else "unknown"
end
```

**`loop` without `break`.** `loop do ... end` runs forever — there's no implicit exit. Always know what condition trips `break`. The same trap hits `while true`.

**Mutating a collection while iterating it.** Adding to the array during `each` keeps iterating the freshly-added elements; deleting shifts indices under the iterator and skips items. Build a new array with `reject`/`select`/`map` instead, or collect a delete-list and apply it after the loop:

```ruby
arr = [1, 2, 3]
seen = []
arr.each { |n| seen << n; arr << n * 10 if n < 3 }
seen   # => [1, 2, 3, 10, 20]   # iteration kept going through appended values
```

**Lazy enumerators need `.force` or `.to_a`.** `(1..).lazy.map { _1 * 2 }` is just a description of work; nothing runs until you ask for results with `.first(n)`, `.to_a`, or `.force`. Forgetting that step gives you back an enumerator object instead of an array, and the bug surfaces as a confusing `inspect` output rather than a crash.

## What you learned

| Concept | Key point |
|---|---|
| `if`/`unless` modifiers | `puts x if cond` |
| `if` as expression | assign the result of an `if` |
| `case/when` | matches via `===` (Integer, Range, Regexp all work) |
| `case/in` | pattern matching: matches *shape* and binds variables |
| `&.` | safe navigation — call only if non-nil |
| `loop`/`break`/`next` | the loose loop, with explicit exit |
| `binding.break` / `binding.pry` in a loop | stop on one iteration and inspect real state |
| `n.times`, `a.upto(b)` | counted loops in idiomatic form |
| `reduce(:+)` / `reduce(0) { ... }` | fold a collection into one value |
| `each_with_object({})` | accumulate into a starting value |
| `group_by { ... }` | split into a hash |
| `partition { ... }` | split into two arrays |
| `chunk_while { ... }` | group consecutive runs |
| `Regexp.new(s, flags)` | build a regex from a string |
| `r.match?(s)` | true/false without MatchData |
| `s[/regex/, 1]` | regex with capture group |
| `^` (XOR) | true when exactly one operand is true |

## Going deeper

`ri Enumerable` from your terminal lists every method this chapter only sampled — `flat_map`, `take_while`, `drop_while`, `each_slice`, `each_cons`, `tally_by`, `lazy`, `find_index`, `minmax`, `sum`, and more. Read the list once. The names are mnemonic enough that, next time you reach for a `while` loop, the right name will surface.

Real `grep` is a few thousand lines of C — most of it argument parsing, locale handling, and Boyer-Moore search. The Ruby `grep.rb` here is fifteen lines and handles 90% of daily use. That ratio (a tenth the code, most of the value) is typical for Ruby vs. C tools, and it's the reason Rails-shaped programs get written in Ruby in the first place.

## Exercises

1. **grep with `-l` flag**: add `-l` (list files only) — print the filename of each file that has any matches, no lines. `ruby grep.rb -l 'ERROR' *.log` lists matching files. Starter: `exercises/1_grep_list_files.rb`.

2. **grep that exits 1 on no matches**: when no patterns match in *any* file, exit with code 1 (useful in shell pipelines like `grep pattern file && echo found`). Starter: `exercises/2_grep_exit_code.rb`.

3. **top_errors with grouping**: extend `top_errors.rb` so errors with the same prefix (e.g., "connection refused: 192.168.1.5" and "connection refused: 192.168.1.6") count as the same error. Hint: strip everything after a colon in the message before tallying. Starter: `exercises/3_top_errors_grouped.rb`.

4. **uptime.rb**: read a log and find the longest run of consecutive minutes with no ERROR entries. Print the start and end timestamps. Hint: `chunk_while`. Starter: `exercises/4_uptime.rb`.

5. **fizzbuzz.rb**: print numbers 1 to 30; for multiples of 3 print "Fizz", for multiples of 5 print "Buzz", for both print "FizzBuzz". Use `case/when` (with `[n % 3, n % 5]` as the value to match against arrays). Starter: `exercises/5_fizzbuzz.rb`.

6. **log_histogram.rb**: extend `log_summary.rb` to print a horizontal bar chart of total entries per hour, like `histogram.rb` from Chapter 2. Bars should scale to a max width of 30. Starter: `exercises/6_log_histogram.rb`.
