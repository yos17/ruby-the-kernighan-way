# Chapter 1 — Getting Started

## Hello, Ruby

The first program in every language:

```ruby
puts "Hello, World!"
```

Run it:
```bash
ruby hello.rb
# Hello, World!
```

Or try it immediately without a file:
```bash
ruby -e 'puts "Hello, World!"'
```

Or use IRB — Ruby's interactive shell (like a calculator):
```bash
irb
> 1 + 1        # => 2
> "hello".upcase  # => "HELLO"
> exit
```

That's all you need to start. No `main()`, no `public static void`, no semicolons. Just code.

---

## How Ruby Runs Your Code

When you run `ruby hello.rb`:
1. Ruby reads your file
2. Parses it into an internal tree
3. Executes it top to bottom

Ruby is **interpreted** — there's no separate compile step. The program runs as soon as you type `ruby filename.rb`.

---

## Variables

```ruby
name    = "Yosia"       # String
age     = 30            # Integer
height  = 1.75          # Float
active  = true          # Boolean (TrueClass)
nothing = nil           # Null (NilClass)

puts name               # Yosia
puts age + 1            # 31
puts "Name: #{name}"    # Name: Yosia   (string interpolation)
puts "Age: " + age.to_s # Age: 30       (explicit conversion)
```

**String interpolation** `#{}` is the Ruby way. It converts the expression to a string automatically. Use it everywhere — it's cleaner than concatenation.

Variable naming convention in Ruby: `snake_case` (words separated by underscores).

---

## Ruby's Four Variable Types

```ruby
local_var  = "local"        # lowercase: local variable
@instance  = "instance"     # @ prefix: instance variable (inside a class)
@@class    = "class"        # @@ prefix: class variable (shared across instances)
CONSTANT   = "constant"     # UPPERCASE: constant (don't reassign)
$global    = "global"       # $ prefix: global (avoid these)
```

You'll mostly use local variables and instance variables. We'll explain when in Chapter 5.

---

## Input and Output

```ruby
print "Enter your name: "   # print = no newline
name = gets.chomp            # gets reads a line; chomp removes the trailing \n
puts "Hello, #{name}!"      # puts = print + newline
```

`gets` always returns a string, including the newline character. `chomp` removes it.

---

## Your First Real Program: A Calculator

```ruby
# calculator.rb — a simple calculator

print "First number: "
a = gets.chomp.to_f   # to_f converts string to Float

print "Operator (+, -, *, /): "
op = gets.chomp

print "Second number: "
b = gets.chomp.to_f

result = case op
         when "+" then a + b
         when "-" then a - b
         when "*" then a * b
         when "/" then
           if b == 0
             "Error: division by zero"
           else
             a / b
           end
         else
           "Unknown operator: #{op}"
         end

puts "Result: #{result}"
```

Run it:
```bash
ruby calculator.rb
First number: 10
Operator: *
Second number: 5
Result: 50.0
```

This is real Ruby. Notice:
- `case/when` instead of `if/elsif/elsif`
- `to_f` converts string to float
- The result of `case` is a value (assigned to `result`)

---

## Command-Line Arguments

```ruby
# greet.rb
name = ARGV[0] || "World"   # ARGV = array of command-line args
puts "Hello, #{name}!"
```

```bash
ruby greet.rb                # Hello, World!
ruby greet.rb Yosia          # Hello, Yosia!
ruby greet.rb "Yosia H"      # Hello, Yosia H!
```

`ARGV` is an array of strings. `ARGV[0]` is the first argument.
`||` means "use this if the left side is nil/false" — a Ruby idiom you'll see constantly.

---

## Comments

```ruby
# Single-line comment

=begin
Multi-line comment
(rarely used — prefer multiple # lines)
=end

name = "Yosia"  # inline comment
```

---

## Exercises

1. Write `greet.rb` that takes a name and optional greeting from command line:
   `ruby greet.rb Yosia "Good morning"` → `Good morning, Yosia!`

2. Write `celsius.rb` that converts Celsius to Fahrenheit:
   `ruby celsius.rb 100` → `100°C = 212.0°F`

3. Extend the calculator to handle `**` (power) and `%` (modulo).

4. Write `echo.rb` that prints all command-line arguments, one per line, numbered:
   ```
   ruby echo.rb one two three
   1: one
   2: two
   3: three
   ```

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| `puts` / `print` | output with/without newline |
| `gets.chomp` | read a line of input |
| `"#{expr}"` | string interpolation |
| `ARGV` | command-line arguments as array |
| `to_f`, `to_i`, `to_s` | type conversion |
| `\|\|` | "use right side if left is nil/false" |
| `case/when` | cleaner than long if/elsif chains |
