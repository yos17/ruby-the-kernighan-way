# Chapter 2 — Types and Expressions

This chapter can feel dense if you read it like a glossary.

A better way to read it is:

- first, notice what kind of value you are working with
- second, ask what methods Ruby gives that value
- third, try one tiny example in IRB

Do not try to memorize every method. Learn the shape of the main value types first.

## Everything is an Object

In Ruby, there are no primitive types. Everything — integers, strings, `true`, `nil` — is an object. Every object has methods.

```ruby
42.class        # => Integer
42.even?        # => true
42.to_s         # => "42"
42.times { |i| print "#{i} " }   # => 0 1 2 ... 41

"hello".class   # => String
"hello".length  # => 5
"hello".upcase  # => "HELLO"

nil.class       # => NilClass
nil.nil?        # => true

true.class      # => TrueClass
true & false    # => false
```

This matters because there are no special rules for primitives. The same object model applies to everything.

---

## Numbers

Numbers are one of the easiest places to see Ruby’s object model.

Even a plain number like `42` can receive methods.

```ruby
# Integers
42
-7
1_000_000       # underscores for readability (one million)
0xFF            # hexadecimal = 255
0b1010          # binary = 10
0o17            # octal = 15

# Floats
3.14
1.5e10          # scientific notation = 15000000000.0
1_234.567_89

# Integer arithmetic
7 / 2           # => 3 (integer division — truncates!)
7.0 / 2         # => 3.5
7 % 2           # => 1 (modulo/remainder)
2 ** 10         # => 1024 (power)

# Useful methods
-42.abs         # => 42
3.14.round      # => 3
3.14.ceil       # => 4
3.14.floor      # => 3
42.zero?        # => false
0.zero?         # => true
255.to_s(16)    # => "ff" (convert to hex string)
```

⚠️ The `7 / 2 = 3` gotcha trips up everyone. If either operand is a float, you get float division.

In plain English:
- `7 / 2` means integer division, so the fractional part is dropped
- `7.0 / 2` means floating-point division, so you get `3.5`

---

## Strings

Strings in Ruby are **mutable** objects (unlike in many languages):

```ruby
# Creation
"double quotes"       # interpolation works: "Hello #{name}"
'single quotes'       # literal: no interpolation, \n stays as \n
%q(another way)       # like single quotes
%Q(yet another)       # like double quotes
<<~HEREDOC            # for multi-line strings
  Hello
  World
HEREDOC

# Common methods
s = "Hello, World!"
s.length              # => 13
s.upcase              # => "HELLO, WORLD!"
s.downcase            # => "hello, world!"
s.reverse             # => "!dlroW ,olleH"
s.include?("World")   # => true
s.start_with?("He")   # => true
s.end_with?("!")      # => true
s.gsub("World", "Ruby")  # => "Hello, Ruby!"
s.split(", ")         # => ["Hello", "World!"]
s.strip               # remove leading/trailing whitespace
s.chomp               # remove trailing newline
s.chars               # => ["H", "e", "l", "l", "o", ...]
s[0]                  # => "H"
s[0, 5]               # => "Hello" (start, length)
s[7..]                # => "World!"  (from index 7 to end)
s[-1]                 # => "!" (negative = from end)

# Useful patterns
"  hello  ".strip.capitalize  # => "Hello"
"hello world".split.map(&:capitalize).join(" ")  # => "Hello World"
"abc" * 3             # => "abcabcabc"
```

### String formatting

```ruby
name  = "Yosia"
score = 98.5

"Name: %-10s Score: %.1f" % [name, score]
# => "Name: Yosia      Score: 98.5"

# sprintf-style:
"%05d" % 42       # => "00042"
"%.2f" % 3.14159  # => "3.14"
```

---

## Symbols

Beginners often get confused here, so keep the rule simple:

- use strings for normal text
- use symbols for names and identifiers

Symbols are like strings but **immutable** and unique. Two symbols with the same name are literally the same object in memory.

```ruby
:hello.class      # => Symbol
:hello == :hello  # => true  (always the same object)
:hello.to_s       # => "hello"
"hello".to_sym    # => :hello

# When to use symbols vs strings:
# Strings: text data, user input, output
# Symbols: names, keys, identifiers

hash = { name: "Yosia", age: 30 }  # symbol keys (most common)
hash[:name]   # => "Yosia"
```

Symbols are used as hash keys, method names, and identifiers throughout Ruby. You'll see `:something` everywhere.

---

## Arrays

```ruby
arr = [1, "two", :three, true, nil]   # mixed types, no problem

# Access
arr[0]        # => 1
arr[-1]       # => nil
arr[1, 3]     # => ["two", :three, true]  (start, count)
arr[1..3]     # => ["two", :three, true]  (range)
arr.first     # => 1
arr.last      # => nil
arr.first(2)  # => [1, "two"]

# Modification
arr.push(42)       # add to end
arr << 99          # also add to end (shovel operator)
arr.pop            # remove and return last
arr.unshift(0)     # add to front
arr.shift          # remove and return first
arr.insert(2, "x") # insert at index 2

# Common operations
[1,2,3].length           # => 3
[1,2,3].reverse          # => [3,2,1]
[3,1,2].sort             # => [1,2,3]
[1,2,2,3].uniq           # => [1,2,3]
[1,2,3].include?(2)      # => true
[1,nil,2,nil,3].compact  # => [1,2,3]  (remove nils)
[1,2,3].sum              # => 6
[1,2,3].min              # => 1
[1,2,3].max              # => 3

# Transformations (return new arrays)
[1,2,3].map { |n| n * 2 }     # => [2,4,6]
[1,2,3,4].select { |n| n.even? }  # => [2,4]
[1,2,3,4].reject { |n| n.even? }  # => [1,3]
[1,2,3].reduce(0) { |sum, n| sum + n }  # => 6
[1,2,3].reduce(:+)                       # => 6 (shorthand)

# Flatten nested arrays
[[1,2],[3,[4,5]]].flatten   # => [1,2,3,4,5]
[[1,2],[3,4]].flatten(1)    # => [1,2,3,4] (one level only)
```

---

## Hashes

```ruby
# Creation
person = { name: "Yosia", age: 30, city: "Amsterdam" }
# same as: { :name => "Yosia", :age => 30 }  (old syntax)

# Access
person[:name]            # => "Yosia"
person[:missing]         # => nil (no KeyError!)
person.fetch(:name)      # => "Yosia"
person.fetch(:missing, "default")  # => "default"
person.fetch(:missing) { |k| "no #{k}" }  # => "no missing"

# Modification
person[:email] = "yosia@example.com"  # add/update
person.delete(:city)                   # remove

# Querying
person.key?(:name)       # => true
person.value?("Yosia")   # => true
person.keys              # => [:name, :age, :email]
person.values            # => ["Yosia", 30, "yosia@example.com"]
person.length            # => 3

# Iteration
person.each { |key, value| puts "#{key}: #{value}" }
person.map  { |key, value| "#{key}=#{value}" }
person.select { |k, v| v.is_a?(String) }
person.any? { |k, v| v == 30 }

# Merging
defaults = { color: "blue", size: "medium" }
options  = { color: "red" }
defaults.merge(options)  # => { color: "red", size: "medium" }
```

---

## Ranges

```ruby
(1..10)      # inclusive: 1 to 10
(1...10)     # exclusive: 1 to 9
('a'..'z')   # works on strings too!

(1..10).to_a          # => [1,2,3,4,5,6,7,8,9,10]
(1..10).include?(5)   # => true
(1..10).sum           # => 55
(1..10).min           # => 1
(1..10).max           # => 10
(1..10).each { |n| print "#{n} " }

# Ranges in case statements:
score = 85
grade = case score
        when 90..100 then "A"
        when 80..89  then "B"
        when 70..79  then "C"
        else              "F"
        end
# => "B"
```

---

## Type Conversion

```ruby
# Explicit (safe — you control when)
"42".to_i       # => 42
"3.14".to_f     # => 3.14
42.to_s         # => "42"
42.to_f         # => 42.0
"42abc".to_i    # => 42  (stops at first non-digit)
"abc".to_i      # => 0   (no digits found)

# Strict (raises exception on failure)
Integer("42")   # => 42
Integer("abc")  # raises ArgumentError

Float("3.14")   # => 3.14
Float("abc")    # raises ArgumentError

# Array/Hash
Array(nil)         # => []
Array([1,2])       # => [1,2]
Array({a: 1})      # => [[:a, 1]]
```

---

## Your Program: A Unit Converter

```ruby
# converter.rb — convert between units
# Usage: ruby converter.rb 100 km miles

CONVERSIONS = {
  ["km",    "miles"]  => ->(v) { v * 0.621371 },
  ["miles", "km"]     => ->(v) { v * 1.60934  },
  ["kg",    "lbs"]    => ->(v) { v * 2.20462  },
  ["lbs",   "kg"]     => ->(v) { v * 0.453592 },
  ["c",     "f"]      => ->(v) { v * 9.0/5 + 32 },
  ["f",     "c"]      => ->(v) { (v - 32) * 5.0/9 },
  ["m",     "ft"]     => ->(v) { v * 3.28084  },
  ["ft",    "m"]      => ->(v) { v * 0.3048   },
}

if ARGV.length != 3
  puts "Usage: converter.rb value from_unit to_unit"
  puts "Example: converter.rb 100 km miles"
  puts "Units: km/miles, kg/lbs, c/f, m/ft"
  exit 1
end

value   = ARGV[0].to_f
from    = ARGV[1].downcase
to      = ARGV[2].downcase
convert = CONVERSIONS[[from, to]]

if convert
  result = convert.call(value)
  puts "#{value} #{from} = #{result.round(4)} #{to}"
else
  puts "Unknown conversion: #{from} → #{to}"
  puts "Available: #{CONVERSIONS.keys.map { |k| k.join('→') }.join(', ')}"
  exit 1
end
```

```bash
ruby converter.rb 100 km miles    # => 100.0 km = 62.1371 miles
ruby converter.rb 37 c f          # => 37.0 c = 98.6 f
ruby converter.rb 75 kg lbs       # => 75.0 kg = 165.3465 lbs
```

Notice the `CONVERSIONS` hash maps `[from, to]` arrays to **lambda** functions. When you look up a conversion, you get a callable object back and call it with `.call(value)`. This is a taste of Chapter 4.

---

## Exercises

1. Add `["l", "gal"]` and `["gal", "l"]` conversions (1 gallon = 3.78541 liters)
2. Write `stats.rb` that takes numbers as arguments and prints min, max, sum, mean, and median
3. Write `anagram.rb` that checks if two words are anagrams: `ruby anagram.rb listen silent` → `true`
4. Build a lookup table for the NATO phonetic alphabet and a converter: `A` → `Alpha`, `B` → `Bravo`, etc.

---

## What You Learned

| Type | Key point |
|------|-----------|
| Integer/Float | `7/2 = 3` (integer division); use `7.0/2` for float |
| String | mutable, rich methods, `"#{interpolation}"` |
| Symbol | immutable, unique, used as keys and identifiers |
| Array | ordered, indexed, powerful iteration methods |
| Hash | key-value map, symbol keys preferred |
| Range | `1..10` inclusive, `1...10` exclusive |
| Conversion | `.to_i`, `.to_f`, `.to_s` for safe conversion |

---

## Solutions

### Exercise 1

```ruby
# Add liter/gallon conversions to converter.rb
# 1 gallon = 3.78541 liters

# Add these two lines to the CONVERSIONS hash in converter.rb:
CONVERSIONS = {
  # ... existing conversions ...
  ["km",    "miles"]  => ->(v) { v * 0.621371 },
  ["miles", "km"]     => ->(v) { v * 1.60934  },
  ["kg",    "lbs"]    => ->(v) { v * 2.20462  },
  ["lbs",   "kg"]     => ->(v) { v * 0.453592 },
  ["c",     "f"]      => ->(v) { v * 9.0/5 + 32 },
  ["f",     "c"]      => ->(v) { (v - 32) * 5.0/9 },
  ["m",     "ft"]     => ->(v) { v * 3.28084  },
  ["ft",    "m"]      => ->(v) { v * 0.3048   },
  # New conversions:
  ["l",     "gal"]    => ->(v) { v / 3.78541  },
  ["gal",   "l"]      => ->(v) { v * 3.78541  },
}

# ruby converter.rb 10 l gal    # => 10.0 l = 2.6417 gal
# ruby converter.rb 1 gal l     # => 1.0 gal = 3.7854 l
```

### Exercise 2

```ruby
# stats.rb — min, max, sum, mean, median of numbers
# Usage: ruby stats.rb 3 1 4 1 5 9 2 6

if ARGV.empty?
  puts "Usage: stats.rb number1 number2 ..."
  exit 1
end

numbers = ARGV.map(&:to_f)
sorted  = numbers.sort
count   = numbers.length
sum     = numbers.sum
mean    = sum / count

median = if count.odd?
           sorted[count / 2]
         else
           (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
         end

puts "Count:  #{count}"
puts "Min:    #{numbers.min}"
puts "Max:    #{numbers.max}"
puts "Sum:    #{sum}"
puts "Mean:   #{mean.round(4)}"
puts "Median: #{median}"

# ruby stats.rb 3 1 4 1 5 9 2 6
# Count:  8
# Min:    1.0
# Max:    9.0
# Sum:    31.0
# Mean:   3.875
# Median: 3.5
```

### Exercise 3

```ruby
# anagram.rb — check if two words are anagrams
# Usage: ruby anagram.rb listen silent

if ARGV.length < 2
  puts "Usage: anagram.rb word1 word2"
  exit 1
end

word1, word2 = ARGV[0].downcase, ARGV[1].downcase

# Two words are anagrams if they have the same sorted characters
result = word1.chars.sort == word2.chars.sort

puts result
# ruby anagram.rb listen silent   # => true
# ruby anagram.rb hello world     # => false
# ruby anagram.rb Astronomer MoonStarer  # => true (case-insensitive)
```

### Exercise 4

```ruby
# nato.rb — NATO phonetic alphabet converter
# Usage: ruby nato.rb hello

NATO = {
  "a" => "Alpha",   "b" => "Bravo",   "c" => "Charlie", "d" => "Delta",
  "e" => "Echo",    "f" => "Foxtrot", "g" => "Golf",    "h" => "Hotel",
  "i" => "India",   "j" => "Juliet",  "k" => "Kilo",    "l" => "Lima",
  "m" => "Mike",    "n" => "November","o" => "Oscar",   "p" => "Papa",
  "q" => "Quebec",  "r" => "Romeo",   "s" => "Sierra",  "t" => "Tango",
  "u" => "Uniform", "v" => "Victor",  "w" => "Whiskey", "x" => "X-ray",
  "y" => "Yankee",  "z" => "Zulu"
}

input = ARGV.join(" ")

if input.empty?
  puts "Usage: nato.rb text"
  exit 1
end

input.downcase.chars.each do |char|
  if NATO.key?(char)
    print "#{NATO[char]} "
  elsif char == " "
    print "/ "
  end
end
puts

# ruby nato.rb SOS   # => Sierra Oscar Sierra
# ruby nato.rb hello # => Hotel Echo Lima Lima Oscar
```
