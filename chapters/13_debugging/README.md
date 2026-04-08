# Chapter 13 — Debugging

## Why Debugging Matters

`puts` debugging works — until it doesn't. When your program has 20 variables and the bug is in a method called from three different places, you need a real debugger. Ruby has excellent ones.

This chapter covers two tools:
- **Pry** — a powerful REPL that drops you inside your running code
- **VSCode + debug gem** — a visual debugger with breakpoints, stepping, and variable inspection

---

## Setup

### Install Pry

```bash
gem install pry
```

### Install the debug gem (for VSCode)

Ruby 3.1+ ships with the `debug` gem. If you're on an older version:

```bash
gem install debug
```

For VSCode, install the **VSCode rdbg Ruby Debugger** extension:
1. Open VSCode
2. Extensions (Cmd+Shift+X)
3. Search "rdbg" or "Ruby Debug"
4. Install **VSCode rdbg Ruby Debugger** by Koichi Sasada

---

## Part 1: Debugging with Pry

### Your First Breakpoint

Pry lets you pause your program and look around. Add `binding.pry` anywhere:

```ruby
# age_checker.rb
require 'pry'

def check_age(name, age)
  binding.pry          # execution stops here
  if age >= 18
    "#{name} is an adult"
  else
    "#{name} is a minor"
  end
end

puts check_age("Alice", 25)
puts check_age("Bob", 15)
```

Run it:
```bash
ruby age_checker.rb
```

You drop into a live session inside `check_age`:
```
    4: def check_age(name, age)
 => 5:   binding.pry
    6:   if age >= 18
    7:     "#{name} is an adult"

[1] pry(main)> name
=> "Alice"
[2] pry(main)> age
=> 25
[3] pry(main)> age >= 18
=> true
[4] pry(main)> exit    # continue execution
```

When it hits the breakpoint the second time, you see Bob's values. Type `exit` again to finish.

### What `binding.pry` Actually Does

`binding` captures the current scope — all local variables, `self`, the call stack. `pry` opens an interactive REPL in that context. You're not simulating anything — you're running real Ruby inside your running program.

---

### Essential Pry Commands

```
Variable inspection:
  name              show a variable's value
  ls                list all variables and methods in scope
  ls -l             long listing with details

Navigation:
  whereami          show surrounding source code
  whereami -n 20    show 20 lines of context
  exit              continue execution (to next breakpoint or end)
  exit!             quit the entire program immediately
  !!!               same as exit! (emergency exit)

Code inspection:
  show-source check_age       show a method's source code
  show-doc String#gsub        show documentation
  cd obj                      step into an object's context
  cd ..                       step back out

Stack:
  caller            show the call stack (Ruby built-in)
  wtf?              show the last exception's backtrace
  wtf?!             show the full backtrace (not truncated)
```

---

### Debugging a Real Bug with Pry

Here's a buggy program. The word counter gives wrong results:

```ruby
# word_counter_buggy.rb
require 'pry'

def count_words(text)
  words = text.split(",")       # BUG: splitting on comma, not space
  frequency = Hash.new(0)

  words.each do |word|
    frequency[word] += 1
  end

  frequency
end

def top_words(text, n = 3)
  counts = count_words(text)
  binding.pry                   # let's inspect what we got
  counts.sort_by { |_, count| -count }.first(n)
end

text = "the cat sat on the mat the cat"
puts "Top words:"
top_words(text).each do |word, count|
  puts "  #{word}: #{count}"
end
```

Run it and use Pry to find the bug:
```
[1] pry(main)> counts
=> {"the cat sat on the mat the cat"=>1}     # one big string!
[2] pry(main)> text.split(",")
=> ["the cat sat on the mat the cat"]         # comma split doesn't work
[3] pry(main)> text.split
=> ["the", "cat", "sat", "on", "the", "mat", "the", "cat"]   # this is right
```

The fix: change `text.split(",")` to `text.split`. In Pry you can even test the fix live before changing the file.

---

### Conditional Breakpoints

When a method is called thousands of times, you don't want to stop every time:

```ruby
def process_user(user)
  binding.pry if user[:name] == "Bob"   # only stop for Bob
  # ... processing
end
```

Or stop only when something looks wrong:

```ruby
def calculate_price(item)
  price = item[:base_price] * item[:quantity]
  binding.pry if price.negative?        # something is wrong
  price
end
```

---

### Pry with Objects

Pry's `cd` command lets you step inside any object:

```ruby
require 'pry'

class BankAccount
  attr_reader :name, :balance, :transactions

  def initialize(name, balance)
    @name = name
    @balance = balance
    @transactions = []
  end

  def deposit(amount)
    @transactions << { type: :deposit, amount: amount }
    @balance += amount
  end
end

account = BankAccount.new("Alice", 100)
account.deposit(50)
account.deposit(25)
binding.pry
```

```
[1] pry(main)> cd account
[2] pry(#<BankAccount>)> name
=> "Alice"
[3] pry(#<BankAccount>)> balance
=> 175
[4] pry(#<BankAccount>)> transactions
=> [{:type=>:deposit, :amount=>50}, {:type=>:deposit, :amount=>25}]
[5] pry(#<BankAccount>)> ls
BankAccount#methods: balance  deposit  name  transactions
instance variables: @balance  @name  @transactions
[6] pry(#<BankAccount>)> cd ..
[7] pry(main)>
```

`cd` is powerful — you can `cd` into a class, a module, even a hash. Use it to explore.

---

## Part 2: Debugging with VSCode

### Why a Visual Debugger?

Pry is great for quick inspections. But when you need to:
- Step through code line by line
- Watch variables change over time
- Set multiple breakpoints and manage them visually
- Debug complex call stacks

...a visual debugger is faster.

---

### Setting Up VSCode for Ruby Debugging

**Step 1:** Create a launch configuration. In your project, create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "rdbg",
      "name": "Debug current file",
      "request": "launch",
      "script": "${file}",
      "args": [],
      "askParameters": false
    },
    {
      "type": "rdbg",
      "name": "Debug with arguments",
      "request": "launch",
      "script": "${file}",
      "args": ["${input:args}"],
      "askParameters": false
    },
    {
      "type": "rdbg",
      "name": "Attach to running process",
      "request": "attach"
    }
  ],
  "inputs": [
    {
      "id": "args",
      "type": "promptString",
      "description": "Command-line arguments"
    }
  ]
}
```

**Step 2:** Open a Ruby file, click in the gutter (left of line numbers) to set a breakpoint (red dot appears).

**Step 3:** Press **F5** or go to **Run > Start Debugging**. Select "Debug current file."

---

### VSCode Debugger Controls

Once paused at a breakpoint, use the toolbar:

```
F5          Continue        — run until next breakpoint
F10         Step Over       — execute current line, don't enter methods
F11         Step Into       — enter the method being called
Shift+F11   Step Out        — finish current method, return to caller
Ctrl+Shift+F5  Restart     — restart the debug session
Shift+F5    Stop            — kill the program
```

The **Variables** panel (left sidebar) shows all locals, instance variables, and globals at the current point. The **Watch** panel lets you track specific expressions. The **Call Stack** panel shows how you got here.

---

### Using the debug Gem Directly

You don't need VSCode to use Ruby's debugger. The `debug` gem works from the terminal too:

```ruby
# Using debugger statement (similar to binding.pry):
require 'debug'

def factorial(n)
  debugger              # stops here
  return 1 if n <= 1
  n * factorial(n - 1)
end

puts factorial(5)
```

```bash
ruby factorial_debug.rb
```

```
[1, 7] in factorial_debug.rb
     1| require 'debug'
     2|
     3| def factorial(n)
=>   4|   debugger
     5|   return 1 if n <= 1
     6|   n * factorial(n - 1)
     7| end

(rdbg) n           # value of n
=> 5

(rdbg) step        # step into next line
(rdbg) next        # step over (don't enter recursive call)
(rdbg) continue    # run until next breakpoint
(rdbg) bt          # show backtrace
(rdbg) info        # show all local variables
(rdbg) watch n     # break when n changes
(rdbg) break 6     # set breakpoint at line 6
(rdbg) q           # quit
```

---

### Debug Gem Commands Reference

```
Stepping:
  step (s)          step into the next method call
  next (n)          step over — execute line, stay in current method
  finish            run until current method returns
  continue (c)      run until next breakpoint

Breakpoints:
  break 15          break at line 15 of current file
  break foo.rb:20   break at line 20 of foo.rb
  break MyClass#bar break when method bar is called
  break if x > 10   conditional breakpoint
  info breakpoints  list all breakpoints
  delete 1          delete breakpoint #1

Inspection:
  p expr            evaluate and print expression
  pp expr           pretty-print
  info              show local variables
  info ivars        show instance variables
  bt                show backtrace (call stack)
  frame 3           switch to frame #3 in the call stack
  list              show source around current line
  outline           show methods of current object

Watch:
  watch expr        break when expression value changes
  watch @balance    break when @balance changes
```

---

## Your Program: Debugging a Buggy Todo App

Here's a todo app with three bugs. Use Pry or the VSCode debugger to find and fix them.

```ruby
# todo_buggy.rb — a todo list with 3 hidden bugs
# Your mission: find and fix them all

class TodoList
  attr_reader :name, :items

  def initialize(name)
    @name = name
    @items = []
  end

  def add(task, priority: :normal)
    @items << { task: task, priority: priority, done: false }
    puts "Added: #{task}"
  end

  def complete(task_name)
    item = @items.find { |i| i[:task] == task_name }
    item[:done] = true                     # BUG 1: no nil check — crashes if task not found
    puts "Completed: #{task_name}"
  end

  def pending
    @items.select { |i| i[:done] }         # BUG 2: selects done items, not pending ones
  end

  def summary
    total = @items.length
    done = @items.count { |i| i[:done] }
    pending = total - done
    percent = (done / total * 100).round    # BUG 3: integer division gives 0
    "#{name}: #{done}/#{total} done (#{percent}%) — #{pending} pending"
  end

  def to_s
    lines = @items.map do |item|
      mark = item[:done] ? "x" : " "
      pri = item[:priority] == :high ? " [!]" : ""
      "  [#{mark}] #{item[:task]}#{pri}"
    end
    "#{@name}:\n#{lines.join("\n")}"
  end
end

# --- Driver code ---

list = TodoList.new("Weekend")
list.add("Buy groceries", priority: :high)
list.add("Clean kitchen")
list.add("Read chapter 13")
list.add("Walk the dog")

list.complete("Buy groceries")
list.complete("Walk the dog")

puts list
puts
puts list.summary
puts
puts "Still pending:"
list.pending.each { |item| puts "  - #{item[:task]}" }
```

### The Fixed Version

```ruby
# todo_fixed.rb — all three bugs fixed

class TodoList
  attr_reader :name, :items

  def initialize(name)
    @name = name
    @items = []
  end

  def add(task, priority: :normal)
    @items << { task: task, priority: priority, done: false }
    puts "Added: #{task}"
  end

  def complete(task_name)
    item = @items.find { |i| i[:task] == task_name }
    if item.nil?                                   # FIX 1: handle missing task
      puts "Task not found: #{task_name}"
      return
    end
    item[:done] = true
    puts "Completed: #{task_name}"
  end

  def pending
    @items.reject { |i| i[:done] }                 # FIX 2: reject done, not select done
  end

  def summary
    total = @items.length
    done = @items.count { |i| i[:done] }
    pending = total - done
    percent = (done.to_f / total * 100).round       # FIX 3: to_f prevents integer division
    "#{name}: #{done}/#{total} done (#{percent}%) — #{pending} pending"
  end

  def to_s
    lines = @items.map do |item|
      mark = item[:done] ? "x" : " "
      pri = item[:priority] == :high ? " [!]" : ""
      "  [#{mark}] #{item[:task]}#{pri}"
    end
    "#{@name}:\n#{lines.join("\n")}"
  end
end

# --- Driver code ---

list = TodoList.new("Weekend")
list.add("Buy groceries", priority: :high)
list.add("Clean kitchen")
list.add("Read chapter 13")
list.add("Walk the dog")

list.complete("Buy groceries")
list.complete("Walk the dog")
list.complete("Nonexistent task")       # no longer crashes

puts list
puts
puts list.summary
puts
puts "Still pending:"
list.pending.each { |item| puts "  - #{item[:task]}" }
```

Run the fixed version:
```bash
ruby todo_fixed.rb
Added: Buy groceries
Added: Clean kitchen
Added: Read chapter 13
Added: Walk the dog
Completed: Buy groceries
Completed: Walk the dog
Task not found: Nonexistent task
Weekend:
  [x] Buy groceries [!]
  [ ] Clean kitchen
  [ ] Read chapter 13
  [x] Walk the dog

Weekend: 2/4 done (50%) — 2 pending

Still pending:
  - Clean kitchen
  - Read chapter 13
```

---

### How to Debug It — Walkthrough

**Bug 1 — NilClass error in `complete`:**

Add `binding.pry` (or `debugger`) before the crash:

```ruby
def complete(task_name)
  item = @items.find { |i| i[:task] == task_name }
  binding.pry
  item[:done] = true
end
```

Call `list.complete("Nonexistent")`. In Pry:
```
[1] pry> item
=> nil
[2] pry> item[:done]    # NoMethodError: undefined method '[]' for nil
```

The fix is clear: check for `nil` before accessing the item.

**Bug 2 — `pending` returns wrong items:**

```ruby
def pending
  result = @items.select { |i| i[:done] }
  binding.pry
  result
end
```

```
[1] pry> result.map { |i| i[:task] }
=> ["Buy groceries", "Walk the dog"]    # these are DONE, not pending!
[2] pry> @items.reject { |i| i[:done] }.map { |i| i[:task] }
=> ["Clean kitchen", "Read chapter 13"] # this is right
```

**Bug 3 — percentage is always 0:**

```ruby
def summary
  total = @items.length
  done = @items.count { |i| i[:done] }
  binding.pry
  percent = (done / total * 100).round
end
```

```
[1] pry> done
=> 2
[2] pry> total
=> 4
[3] pry> done / total         # => 0 (integer division!)
[4] pry> done.to_f / total    # => 0.5 (float division)
```

---

## Exercises

1. **Pry exploration:** Open IRB or Pry and explore the `String` class. Use `ls String` to see all methods. Use `show-source String#gsub` to read its implementation. Find a method you didn't know existed.

2. **Debug this:** The following method should return the second-largest number, but it doesn't always work. Use Pry to find the bug:
   ```ruby
   def second_largest(arr)
     sorted = arr.sort
     sorted[-2]
   end

   second_largest([3, 1, 4, 1, 5, 9])  # works: 5
   second_largest([3, 3, 3])            # returns 3, but should it?
   second_largest([5])                  # returns 5, should return nil
   ```

3. **VSCode practice:** Create a `.vscode/launch.json` for this project. Set a breakpoint inside the `TodoList#add` method. Step through with F10/F11. Watch the `@items` array grow in the Variables panel.

4. **Build a debug helper:** Write a `DebugLog` module that you can include in any class. It should add a `debug` method that prints the object's instance variables with their values, formatted nicely. No Pry required — this is your own mini-debugger:
   ```ruby
   class User
     include DebugLog
     def initialize(name, age)
       @name = name
       @age = age
     end
   end

   User.new("Alice", 30).debug
   # [DEBUG User] @name="Alice" @age=30
   ```

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| `binding.pry` | pause execution, open interactive REPL |
| `ls` in Pry | list variables and methods in scope |
| `cd` / `cd ..` | step into/out of objects |
| `whereami` | show current source context |
| `wtf?` | show last exception backtrace |
| `debugger` | pause execution (debug gem / VSCode) |
| F10 / F11 | step over / step into (VSCode) |
| `break` / `watch` | set breakpoints and watchpoints (debug gem) |
| `info` | show local/instance variables (debug gem) |
| Conditional breakpoint | `binding.pry if condition` |

---

## Solutions

### Exercise 1

```
$ pry
[1] pry(main)> ls String
String.methods: try_convert
String#methods:
  %  +  +@  -@  <<  <=>  ==  ===  =~  []  []=  ascii_only?  b  bytes
  bytesize  byteslice  capitalize  capitalize!  casecmp  casecmp?  center
  chars  chomp  chomp!  chop  chop!  chr  clear  codepoints  concat  count
  crypt  delete  delete!  delete_prefix  delete_prefix!  delete_suffix
  delete_suffix!  downcase  downcase!  dump  each_byte  each_char
  each_codepoint  each_grapheme_cluster  each_line  empty?  encode
  encode!  encoding  end_with?  eql?  freeze  getbyte  grapheme_clusters
  gsub  gsub!  hash  hex  include?  index  insert  inspect  intern  dup
  length  lines  ljust  lstrip  lstrip!  match  match?  next  next!  oct
  ord  pack  partition  prepend  replace  reverse  reverse!  rindex  rjust
  rpartition  rstrip  rstrip!  scan  scrub  scrub!  setbyte  shellescape
  shellsplit  size  slice  slice!  split  squeeze  squeeze!  start_with?
  strip  strip!  sub  sub!  succ  succ!  sum  swapcase  swapcase!  to_c
  to_f  to_i  to_r  to_s  to_str  to_sym  tr  tr!  tr_s  tr_s!  undump
  unicode_normalize  unicode_normalize!  unpack  unpack1  upcase  upcase!
  upto  valid_encoding?

# Interesting discovery: String#squeeze removes consecutive duplicate chars
[2] pry(main)> "aabbccdd".squeeze
=> "abcd"
[3] pry(main)> "hello    world".squeeze(" ")
=> "hello world"
```

### Exercise 2

```ruby
# second_largest — fixed
require 'pry'

def second_largest(arr)
  binding.pry
  sorted = arr.sort
  sorted[-2]
end

# In Pry:
# [1] pry> arr
# => [3, 3, 3]
# [2] pry> arr.sort
# => [3, 3, 3]
# [3] pry> arr.uniq.sort
# => [3]
# [4] pry> arr.uniq.sort[-2]
# => nil          # correct! only one unique value

# Fixed version:
def second_largest(arr)
  unique = arr.uniq.sort
  return nil if unique.length < 2
  unique[-2]
end

second_largest([3, 1, 4, 1, 5, 9])  # => 5
second_largest([3, 3, 3])            # => nil
second_largest([5])                  # => nil
second_largest([1, 2])               # => 1
```

### Exercise 3

`.vscode/launch.json` is already provided in the chapter above. Steps:

1. Open `todo_fixed.rb` in VSCode
2. Click the gutter on the `@items <<` line in the `add` method — a red dot appears
3. Press F5, choose "Debug current file"
4. Execution pauses at your breakpoint
5. In the Variables panel, expand `self` > `@items` — it's empty `[]`
6. Press F10 (Step Over) — now `@items` has one element
7. Press F5 (Continue) — it stops again on the next `add` call
8. Watch `@items` grow with each call

### Exercise 4

```ruby
# debug_log.rb — a mini debug helper

module DebugLog
  def debug
    vars = instance_variables.map do |var|
      "#{var}=#{instance_variable_get(var).inspect}"
    end
    puts "[DEBUG #{self.class}] #{vars.join(' ')}"
  end
end

class User
  include DebugLog

  def initialize(name, age, role: :member)
    @name = name
    @age = age
    @role = role
  end
end

class Order
  include DebugLog

  def initialize(id, items)
    @id = id
    @items = items
    @total = items.sum { |i| i[:price] }
  end
end

User.new("Alice", 30).debug
# [DEBUG User] @name="Alice" @age=30 @role=:member

User.new("Bob", 25, role: :admin).debug
# [DEBUG User] @name="Bob" @age=25 @role=:admin

Order.new(42, [{name: "Book", price: 15}, {name: "Pen", price: 3}]).debug
# [DEBUG Order] @id=42 @items=[{:name=>"Book", :price=>15}, {:name=>"Pen", :price=>3}] @total=18
```
