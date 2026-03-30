# Chapter 3 — Control Flow

## if / unless / elsif / else

```ruby
# Standard if
if score >= 90
  puts "A"
elsif score >= 80
  puts "B"
else
  puts "F"
end

# unless = if not
unless logged_in
  redirect_to "/login"
end

# One-liners (postfix form) — very Ruby
puts "Welcome!" if logged_in
puts "Access denied" unless admin?
return if name.nil?
```

**Everything in Ruby returns a value**, including `if`:

```ruby
grade = if score >= 90 then "A"
         elsif score >= 80 then "B"
         else "F"
         end
# Don't write it this way — use case instead
```

---

## case / when

```ruby
# Match a value
case status
when "active"   then puts "Active"
when "pending"  then puts "Pending"
when "closed"   then puts "Closed"
else                 puts "Unknown: #{status}"
end

# Match ranges
case age
when 0..12  then "Child"
when 13..17 then "Teen"
when 18..64 then "Adult"
when 65..   then "Senior"
end

# Match types
case value
when Integer then "it's an integer"
when String  then "it's a string"
when Array   then "it's an array"
when NilClass then "it's nil"
end

# Match regex
case email
when /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  puts "Valid email"
else
  puts "Invalid email"
end

# No value — acts like if/elsif
case
when score >= 90 then "A"
when score >= 80 then "B"
else "F"
end
```

`case` in Ruby uses `===` (triple equals) for matching. `Range#===` checks if a value is in the range. `Regexp#===` checks if a string matches. `Class#===` checks if an object is an instance. This is why `case` is so flexible.

---

## Loops

### times, upto, downto, step

```ruby
5.times { |i| print "#{i} " }          # 0 1 2 3 4
1.upto(5) { |i| print "#{i} " }        # 1 2 3 4 5
5.downto(1) { |i| print "#{i} " }      # 5 4 3 2 1
1.step(10, 2) { |i| print "#{i} " }    # 1 3 5 7 9
```

### each — the Ruby loop

```ruby
[1, 2, 3].each { |n| puts n }

["Alice", "Bob", "Charlie"].each do |name|
  puts "Hello, #{name}!"
end

# With index
["a", "b", "c"].each_with_index do |item, i|
  puts "#{i}: #{item}"
end

# Or cleaner:
["a", "b", "c"].each.with_index(1) do |item, i|
  puts "#{i}: #{item}"   # starts at 1
end

# Hashes
{a: 1, b: 2}.each { |key, val| puts "#{key} = #{val}" }
```

### while / until

```ruby
count = 0
while count < 5
  puts count
  count += 1
end

# until = while not
until done
  process_next_item
end

# Postfix (one-liners)
count += 1 while count < 10
process_next until queue.empty?
```

### loop — infinite loop with break

```ruby
loop do
  input = gets.chomp
  break if input == "quit"
  puts "You said: #{input}"
end
```

### for — rarely used in Ruby

```ruby
for i in 1..5
  puts i
end
# Works but not idiomatic — use .each instead
```

---

## next, break, redo

```ruby
# next = skip to next iteration (like continue in C)
[1,2,3,4,5].each do |n|
  next if n.even?
  puts n             # prints 1, 3, 5
end

# break = exit the loop (with optional return value)
result = [1,2,3,4,5].each do |n|
  break n * 10 if n == 3
end
result    # => 30

# break with value from while:
answer = while true
  guess = gets.to_i
  break guess if guess == 42
end

# redo = restart current iteration (rare)
```

---

## The Ternary Operator

```ruby
status = age >= 18 ? "adult" : "minor"

# Same as:
status = if age >= 18 then "adult" else "minor" end

# Use ternary for short, clear conditions
# Use if/else for anything complex
```

---

## Boolean Logic

```ruby
# and, or, not (low precedence — use for control flow)
# &&, ||, !  (high precedence — use in expressions)

# Truthy/falsy in Ruby:
# ONLY nil and false are falsy. Everything else is truthy!
# 0 is truthy. "" is truthy. [] is truthy.

nil   ? "truthy" : "falsy"   # => "falsy"
false ? "truthy" : "falsy"   # => "falsy"
0     ? "truthy" : "falsy"   # => "truthy"  ← DIFFERENT from JS/C!
""    ? "truthy" : "falsy"   # => "truthy"
[]    ? "truthy" : "falsy"   # => "truthy"

# Guard patterns
name = name || "default"     # use default if nil
name ||= "default"           # same, shorter

value = value && value.upcase  # only call upcase if not nil
value = value&.upcase          # same, using safe navigation (&.)
```

### The Safe Navigation Operator `&.`

```ruby
user = find_user(id)         # might return nil

# Without &.:
if user && user.profile && user.profile.avatar
  show_avatar(user.profile.avatar)
end

# With &.:
show_avatar(user&.profile&.avatar)
# Each &. returns nil if the receiver is nil, instead of raising NoMethodError
```

---

## Your Program: Number Guessing Game

```ruby
# guess.rb — number guessing game with attempts counter

SECRET  = rand(1..100)
MAX     = 7
attempts = 0

puts "I'm thinking of a number between 1 and 100."
puts "You have #{MAX} guesses."

loop do
  attempts += 1
  remaining = MAX - attempts

  print "\nGuess ##{attempts}: "
  guess = gets.chomp.to_i

  if guess < 1 || guess > 100
    puts "Please guess between 1 and 100."
    attempts -= 1
    next
  end

  case guess <=> SECRET
  when -1
    puts "Too low! #{remaining > 0 ? "#{remaining} guesses left." : "Last guess!"}"
  when 1
    puts "Too high! #{remaining > 0 ? "#{remaining} guesses left." : "Last guess!"}"
  when 0
    puts "🎉 Correct! You got it in #{attempts} #{"guess".then { |w| attempts == 1 ? w : w+"es" }}."
    break
  end

  if attempts >= MAX
    puts "\n💀 Game over! The number was #{SECRET}."
    break
  end
end
```

New things here:
- `rand(1..100)` — random integer in range
- `<=>` (spaceship operator) — returns -1, 0, or 1
- `"guess".then { |w| ... }` — call a block with the object (tap into any expression)

---

## Exercises

1. Extend the guessing game to play again after winning/losing (ask "Play again? y/n")
2. Write `fizzbuzz.rb`: print 1-100, but "Fizz" for multiples of 3, "Buzz" for 5, "FizzBuzz" for both
3. Write `prime.rb`: check if a number is prime. Then print all primes up to N.
4. Write `collatz.rb`: given a number, repeatedly apply: if even → n/2, if odd → 3n+1. Count steps until you reach 1.

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| `if`/`unless` | postfix form: `return if nil?` |
| `case`/`when` | uses `===` — matches ranges, types, regex |
| `.each` | the idiomatic Ruby loop |
| `next`/`break` | skip iteration / exit loop |
| Truthy/falsy | only `nil` and `false` are falsy — `0` and `""` are truthy! |
| `\|\|=` | assign if nil: `x ||= default` |
| `&.` | safe navigation: `user&.name` returns nil instead of raising |
| `<=>` | spaceship: -1, 0, 1 — used for sorting and comparison |
