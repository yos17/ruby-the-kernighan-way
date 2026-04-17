# Chapter 1 — A Tutorial Introduction

This chapter introduces Ruby through three programs: a greeter that takes input from you, a calculator that does real arithmetic with command-line arguments, and a tiny file processor that counts lines. By the end you'll have variables, conditionals, methods, command-line arguments, and basic file I/O. The rest of the book goes deeper on each piece; this chapter establishes them all at once so you can read Ruby code without staring at unknown words.

## hello.rb, expanded

You wrote `hello.rb` in Chapter 0:

```ruby
puts "Hello, World!"
```

Change it to greet you by name:

```ruby
name = "Yosia"
puts "Hello, #{name}!"

# => Hello, Yosia!
```

Two things to notice.

`name = "Yosia"` defines a *variable*. The name `name` now refers to the string `"Yosia"`. Ruby variables don't need to be declared first or given a type — assignment creates them.

`"Hello, #{name}!"` is *string interpolation*. The `#{...}` inserts the value of an expression into a string. The expression here is just `name`; it could be any Ruby code — `"Hello, #{name.upcase}!"` would print `Hello, YOSIA!`.

You could write the same thing with concatenation:

```ruby
puts "Hello, " + name + "!"
```

But interpolation is the Ruby way. Use it.

### Asking for the name

Hardcoding `"Yosia"` is no fun. Ask the user:

```ruby
print "What is your name? "
name = gets.chomp
puts "Hello, #{name}!"
```

Run it:

```
$ ruby hello.rb
What is your name? Yosia
Hello, Yosia!
```

Three new things.

`print` is like `puts` but doesn't add a newline. The cursor stays on the same line so the user can type next to the prompt.

`gets` reads one line of input from the keyboard. It returns a string.

`.chomp` removes the trailing newline character that `gets` includes (when the user pressed Enter, that's a newline). Without `.chomp`, your name would have a `\n` glued to the end. Printing would *look* right but `name == "Yosia"` would be false because `"Yosia\n" != "Yosia"`.

`gets.chomp` is one of the most common Ruby idioms. You'll write it constantly.

The full file is in `examples/hello.rb`.

## calc.rb — variables, arithmetic, and methods

A calculator. Two numbers and an operator. A real one — not a single-purpose adder.

Start simple:

```ruby
# calc.rb
a = 10
b = 5

puts "#{a} + #{b} = #{a + b}"

# => 10 + 5 = 15
```

Good. But interesting calculators take input. Read it from the command line:

```ruby
# calc.rb
a = ARGV[0].to_f
op = ARGV[1]
b = ARGV[2].to_f

case op
when "+" then puts a + b
when "-" then puts a - b
when "*" then puts a * b
when "/" then puts a / b
end
```

Run:

```
$ ruby calc.rb 10 + 5
15.0
$ ruby calc.rb 10 / 4
2.5
```

A lot is going on.

`ARGV` is an array of strings — every word the user typed after `ruby calc.rb`. So `ARGV[0]` is `"10"`, `ARGV[1]` is `"+"`, `ARGV[2]` is `"5"`.

`.to_f` converts a string to a float (a number with a decimal point). Without it, `"10" + "5"` would be `"105"` — string concatenation, not arithmetic. Always convert command-line input.

`case ... when` is Ruby's switch statement. Cleaner than nested `if`. The `then` is optional; we could write each branch on its own line.

Run with a bad operator:

```
$ ruby calc.rb 10 % 5
$
```

Nothing happens. The `case` had no `else`, so unrecognized operators silently print nothing. Add a default:

```ruby
case op
when "+" then puts a + b
when "-" then puts a - b
when "*" then puts a * b
when "/" then puts a / b
else
  puts "Unknown operator: #{op}"
end
```

```
$ ruby calc.rb 10 % 5
Unknown operator: %
```

Better.

### Division by zero

What about `ruby calc.rb 10 / 0`?

```
$ ruby calc.rb 10 / 0
Infinity
```

Float division by zero in Ruby returns `Infinity`, not an error. (Integer division would raise `ZeroDivisionError`.) For a real calculator we should check:

```ruby
when "/" then
  if b == 0
    puts "Cannot divide by zero"
  else
    puts a / b
  end
```

Multi-line `when` body — drop the `then` keyword, indent the body.

### Extracting a method

The four arithmetic branches are similar. Pull the work into a method:

```ruby
def calculate(a, op, b)
  case op
  when "+" then a + b
  when "-" then a - b
  when "*" then a * b
  when "/"
    return "Cannot divide by zero" if b == 0
    a / b
  else
    "Unknown operator: #{op}"
  end
end

a  = ARGV[0].to_f
op = ARGV[1]
b  = ARGV[2].to_f

puts calculate(a, op, b)
```

`def name(args) ... end` defines a method. The last expression evaluated is the return value — no explicit `return` needed for the simple branches. The `return ... if condition` form is `if` as a *modifier* — short for "return if this condition is true."

Run it; same behavior. The code reads better, and `calculate` could now be called from elsewhere if you wanted to.

The full file is in `examples/calc.rb`.

## tiny_processor.rb — files and iteration

Count lines in a file.

```ruby
# tiny_processor.rb — count lines in a file
filename = ARGV[0]

count = 0
File.foreach(filename) do |line|
  count += 1
end

puts "#{filename}: #{count} lines"
```

Make a test file `notes.txt` (one is in `examples/notes.txt` next to this chapter):

```
First line
Second line
Third line
```

Run:

```
$ ruby tiny_processor.rb notes.txt
notes.txt: 3 lines
```

What's new.

`File.foreach(filename)` reads the file one line at a time. It takes a *block* — the `do |line| ... end` part — and runs the block once per line, with `line` set to that line.

`count += 1` is shorthand for `count = count + 1`. (So is `+=`, `-=`, `*=`, `/=`.)

Blocks are central to Ruby. Almost every collection method takes a block. We do them properly in Chapter 4.

### Better output

Count lines, words, and characters:

```ruby
filename = ARGV[0]

lines = 0
words = 0
chars = 0

File.foreach(filename) do |line|
  lines += 1
  words += line.split.length
  chars += line.length
end

puts "#{lines} lines, #{words} words, #{chars} characters"
```

`line.split` splits a string on whitespace into an array of pieces. `.length` returns its size. `line.length` is the string's character count.

Run:

```
$ ruby tiny_processor.rb notes.txt
3 lines, 6 words, 34 characters
```

You just wrote a (very tiny) `wc`. Chapter 2 makes a real one.

The full file is in `examples/tiny_processor.rb`.

## Common pitfalls

- **Forgetting `.chomp`.** `name = gets` keeps the trailing newline. Comparisons like `name == "Yosia"` then fail silently. Always pair `gets` with `.chomp` unless you have a reason not to.
- **Doing math on `gets` without converting.** `gets.chomp` returns a string. `gets.chomp + 1` raises `TypeError`. Use `gets.chomp.to_i` for integers, `.to_f` for floats.
- **Confusing `gets` with `ARGV`.** `gets` reads from the keyboard while the program runs; `ARGV` holds words typed *after* the script name (`ruby calc.rb 10 + 5`). A program waiting at a `gets` prompt has not crashed — it wants you to type something and press Enter.
- **`ARGV[0]` is always a string.** Even `ruby calc.rb 10` gives you `"10"`, not `10`. `"10" * 3` is `"101010"`, not `30`. Convert with `.to_i` or `.to_f` before doing math.
- **Shell expands `*` before Ruby sees it.** `ruby calc.rb 10 * 5` may pass every filename in the directory as `ARGV[1]`. Quote it: `ruby calc.rb 10 '*' 5`. Same for `?` and `~`.
- **`puts` adds a newline; `print` does not.** Output that runs together on one line means you wanted `puts`. A prompt that pushes the user's input onto the next line means you wanted `print`.

## What you learned

| Concept | Key point |
|---|---|
| `name = value` | assigns `name` to a value |
| `"#{expr}"` | string interpolation — embed any Ruby expression |
| `gets.chomp` | read one line of input, strip the newline |
| `ARGV` | array of command-line arguments (strings) |
| `.to_f` / `.to_i` | string → number; do it explicitly |
| `case ... when ... else ... end` | clean alternative to nested `if`/`elsif` |
| `def name(args) ... end` | defines a method; returns last expression |
| `expr if condition` | one-line if-modifier form |
| `File.foreach(file) do \|line\| ... end` | iterate a file one line at a time |
| `string.split` | split on whitespace into an array |
| `+=`, `-=`, `*=`, `/=` | shorthand math-assignment |

## Going deeper

- Read the docs for `String` and `Integer` at `https://docs.ruby-lang.org/en/master/String.html` and `https://docs.ruby-lang.org/en/master/Integer.html`. Skim the method lists. You won't remember them — the goal is to know roughly what's there so you can grep the page later.
- Challenge: rewrite `calc.rb` so it can chain operations: `ruby calc.rb 10 + 5 \* 2` prints `30.0`. You'll need to walk `ARGV` in pairs. Don't worry about operator precedence — left-to-right is fine. This is a real exercise; budget thirty minutes.
- Read the source of `wc` from the GNU coreutils — or, easier, run `ruby -e 'puts File.read("/etc/hosts").lines.size'` and compare to `wc -l < /etc/hosts`. Notice that the Ruby version is one line. The C version is hundreds. Both have their place.

## Exercises

Each exercise has a starter file in `exercises/` with `# TODO:` markers. Solutions are in `exercises/solutions/`. Look at them only after you've tried.

1. **`hello.rb` with a greeting**: extend `hello.rb` to also accept the time of day as a second argument. `ruby hello.rb Yosia morning` prints `Good morning, Yosia!`. Support `morning`, `afternoon`, `evening`, and a default greeting when no time is given. Starter: `exercises/1_hello_with_greeting.rb`.

2. **`calc.rb` with `**` and `%`**: add power (`**`) and modulo (`%`) operators to `calc.rb`. Test with `ruby calc.rb 2 ** 10` (= `1024.0`) and `ruby calc.rb 17 % 5` (= `2.0`). Starter: `exercises/2_calc_power_modulo.rb`.

3. **`calc.rb` usage message**: when `ARGV` doesn't have exactly three items, print `Usage: ruby calc.rb <a> <op> <b>` and exit. Hint: `ARGV.length` and `exit 1`. Starter: `exercises/3_calc_usage_message.rb`.

4. **`tiny_processor.rb` with multiple files**: extend `tiny_processor.rb` to accept multiple filenames. Print one line per file plus a total. Hint: `ARGV.each do |filename| ... end`. Starter: `exercises/4_processor_multiple_files.rb`.

5. **`tiny_processor.rb` with stdin**: when no files are given, read from standard input. Hint: `STDIN.each_line do |line| ... end`. Run with `cat notes.txt | ruby chapters/01_tutorial/exercises/5_processor_stdin.rb`. Starter: `exercises/5_processor_stdin.rb`.

6. **`echo.rb`**: write a new program that prints each command-line argument on its own line, numbered. `ruby echo.rb one two three` should print:

   ```
   1: one
   2: two
   3: three
   ```

   Starter: `exercises/6_echo.rb`.
