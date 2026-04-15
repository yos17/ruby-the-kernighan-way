# Chapter 13 — Debugging

This chapter is here because writing code and fixing code are both part of programming.

Beginners often think debugging means “I failed.” Really, debugging means “now I am inspecting what the program actually did.”

## Why Debugging Matters

`puts` debugging works — until it doesn't. When your program has 20 variables and the bug is in a method called from three different places, you need a real debugger. Ruby has excellent ones.

This chapter covers two approaches:
- **`binding.irb`** — a built-in REPL with stepping (Ruby 3.3+, no gems needed)
- **VSCode + debug gem** — a visual debugger with breakpoints, stepping, and variable inspection

We also cover **Pry** (a popular third-party REPL) and explain why `binding.irb` has replaced the old `pry` + `pry-byebug` combo.

If you are new, start with `binding.irb`. It is the shortest path to understanding what your code is doing.

---

## Setup

### Nothing to install (Ruby 3.3+)

Ruby 3.3+ ships with everything you need: **IRB** (the REPL) and the **debug** gem (the stepping engine) are both built in. When you use `binding.irb`, IRB automatically integrates with the debug gem — giving you a Pry-like REPL *plus* `step`, `next`, `continue`.

```bash
ruby --version    # need 3.3+, you have 3.4
```

No `gem install` required. No Gemfile entry. It just works.

### What about Pry and pry-byebug?

| Gem | Status | Recommendation |
|-----|--------|----------------|
| `pry` | Active | Still useful for exploration, but `irb` now has most features |
| `pry-byebug` | **Dead** | Doesn't work on Ruby 3.2+ — replaced by debug gem |
| `byebug` | **Dead** | Same — unmaintained, Ruby ≤ 3.1 only |
| `debug` | **Built-in** | The official debugger since Ruby 3.1 |

**Bottom line:** Use `binding.irb` for the best of both worlds. Use Pry only if you need its unique features (`cd` into objects, `show-source`).

For VSCode, install the **VSCode rdbg Ruby Debugger** extension:
1. Open VSCode
2. Extensions (Cmd+Shift+X)
3. Search "rdbg" or "Ruby Debug"
4. Install **VSCode rdbg Ruby Debugger** by Koichi Sasada

---

## Part 1: Debugging with `binding.irb` (The Modern Way)

### Your First Breakpoint

`binding.irb` pauses your program and drops you into a REPL — no gems required:

```ruby
# age_checker.rb

def check_age(name, age)
  binding.irb          # execution stops here
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
From: age_checker.rb @ line 4

    2|
    3| def check_age(name, age)
 => 4|   binding.irb
    5|   if age >= 18
    6|     "#{name} is an adult"

irb(main):001> name
=> "Alice"
irb(main):002> age
=> 25
irb(main):003> age >= 18
=> true
irb(main):004> continue    # run to next breakpoint or end
```

When it hits the breakpoint the second time, you see Bob's values. Type `continue` again to finish.

### What `binding.irb` Actually Does

This is the key beginner idea of the chapter: the program pauses, and you get to inspect the real state at that exact moment.

`binding` captures the current scope — all local variables, `self`, the call stack. `.irb` opens an interactive REPL in that context. You're not simulating anything — you're running real Ruby inside your running program.

Since Ruby 3.3, IRB automatically loads the `debug` gem, so you get **stepping commands for free** — no extra setup.

---

### Essential `binding.irb` Commands

```
Inspection (IRB built-in):
  name              show a variable's value
  ls                list methods on an object (e.g., ls "hello")
  show_source method_name    show a method's source code
  whereami          show surrounding source code
  caller            show the call stack

Stepping (from debug gem — works automatically):
  step  (s)         step into the next method call
  next  (n)         step over — execute line, stay in current method
  finish            run until current method returns
  continue (c)      run until next breakpoint or end
  info              show all local variables
  info ivars        show instance variables
  backtrace (bt)    show the full call stack
  break 20          set a breakpoint at line 20
  break MyClass#foo break when method is called
  watch @balance    break when value changes
  catch Exception   break when exception is raised

Exit:
  continue          continue execution
  exit              same as continue
  exit!             quit the entire program immediately
  q                 quit
```

This is what `pry` + `pry-byebug` used to give you — but now it's **zero dependencies**.

---

### Debugging a Real Bug

Here's a buggy program. The word counter gives wrong results:

```ruby
# word_counter_buggy.rb

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
  binding.irb                   # let's inspect what we got
  counts.sort_by { |_, count| -count }.first(n)
end

text = "the cat sat on the mat the cat"
puts "Top words:"
top_words(text).each do |word, count|
  puts "  #{word}: #{count}"
end
```

Run it and inspect:
```
irb(main):001> counts
=> {"the cat sat on the mat the cat"=>1}     # one big string!
irb(main):002> text.split(",")
=> ["the cat sat on the mat the cat"]         # comma split doesn't work
irb(main):003> text.split
=> ["the", "cat", "sat", "on", "the", "mat", "the", "cat"]   # this is right
irb(main):004> next                          # step to the next line
irb(main):005> continue                      # resume execution
```

The fix: change `text.split(",")` to `text.split`. In the REPL you can test the fix live before changing the file.

---

### Conditional Breakpoints

When a method is called thousands of times, you don't want to stop every time:

```ruby
def process_user(user)
  binding.irb if user[:name] == "Bob"   # only stop for Bob
  # ... processing
end
```

Or stop only when something looks wrong:

```ruby
def calculate_price(item)
  price = item[:base_price] * item[:quantity]
  binding.irb if price.negative?        # something is wrong
  price
end
```

---

### Stepping Through Code — A Full Example

```ruby
# stepping_demo.rb

def greet(name)
  greeting = "Hello, #{name}"
  greeting.upcase
end

def main
  binding.irb              # start here
  result = greet("Ruby")
  puts result
end

main
```

```
irb(main):001> step         # step INTO greet()
# now inside greet(), line: greeting = "Hello, #{name}"
irb(main):002> info         # show local variables
%self = main
name = "Ruby"
irb(main):003> next         # execute this line, stay in greet()
irb(main):004> info
%self = main
name = "Ruby"
greeting = "Hello, Ruby"
irb(main):005> finish       # finish greet(), return to main
irb(main):006> result
=> "HELLO, RUBY"
irb(main):007> continue     # resume execution
```

This is everything `pry-byebug` used to do — with zero gems.

---

### What About Pry?

Pry (`gem install pry`) is still useful for one thing `binding.irb` can't do: **`cd` into objects**.

```ruby
require 'pry'

account = BankAccount.new("Alice", 100)
binding.pry
```

```
[1] pry(main)> cd account
[2] pry(#<BankAccount>)> @balance
=> 100
[3] pry(#<BankAccount>)> ls
BankAccount#methods: balance  deposit  name  transactions
instance variables: @balance  @name  @transactions
[4] pry(#<BankAccount>)> cd ..
```

If you don't need `cd`, **stick with `binding.irb`** — it's built in and has stepping.

---

## Part 2: Debugging with VSCode

### Why a Visual Debugger?

`binding.irb` is great for quick inspections. But when you need to:
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
# Using debugger statement (alternative to binding.irb):
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

Here's a todo app with three bugs. Use `binding.irb` or the VSCode debugger to find and fix them.

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

Add `binding.irb` before the crash:

```ruby
def complete(task_name)
  item = @items.find { |i| i[:task] == task_name }
  binding.irb
  item[:done] = true
end
```

Call `list.complete("Nonexistent")`. In the REPL:
```
irb> item
=> nil
irb> item[:done]    # NoMethodError: undefined method '[]' for nil
```

The fix is clear: check for `nil` before accessing the item.

**Bug 2 — `pending` returns wrong items:**

```ruby
def pending
  result = @items.select { |i| i[:done] }
  binding.irb
  result
end
```

```
irb> result.map { |i| i[:task] }
=> ["Buy groceries", "Walk the dog"]    # these are DONE, not pending!
irb> @items.reject { |i| i[:done] }.map { |i| i[:task] }
=> ["Clean kitchen", "Read chapter 13"] # this is right
```

**Bug 3 — percentage is always 0:**

```ruby
def summary
  total = @items.length
  done = @items.count { |i| i[:done] }
  binding.irb
  percent = (done / total * 100).round
end
```

```
irb> done
=> 2
irb> total
=> 4
irb> done / total         # => 0 (integer division!)
irb> done.to_f / total    # => 0.5 (float division)
```

---

## Exercises

1. **IRB exploration:** Open IRB and explore the `String` class. Use `ls String` to see all methods. Use `show_source String#gsub` to read its implementation. Find a method you didn't know existed.

2. **Debug this:** The following method should return the second-largest number, but it doesn't always work. Use `binding.irb` to find the bug:
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
| `binding.irb` | pause execution, open REPL with stepping (no gems needed) |
| `step` / `next` | step into / step over (in `binding.irb`) |
| `continue` | resume execution until next breakpoint |
| `finish` | run until current method returns |
| `info` | show local/instance variables |
| `break` / `watch` | set breakpoints and watchpoints |
| `debugger` | alternative breakpoint (debug gem directly) |
| F10 / F11 | step over / step into (VSCode) |
| Conditional breakpoint | `binding.irb if condition` |
| `pry` + `cd` | step into objects (Pry only, optional gem) |

---

## Solutions

### Exercise 1

```
$ irb
irb(main):001> ls String
# (lists all String methods)

irb(main):002> show_source String#gsub
# (shows the source code)

# Interesting discovery: String#squeeze removes consecutive duplicate chars
irb(main):003> "aabbccdd".squeeze
=> "abcd"
irb(main):004> "hello    world".squeeze(" ")
=> "hello world"
```

### Exercise 2

```ruby
# second_largest — fixed

def second_largest(arr)
  binding.irb
  sorted = arr.sort
  sorted[-2]
end

# In the REPL:
# irb> arr
# => [3, 3, 3]
# irb> arr.sort
# => [3, 3, 3]
# irb> arr.uniq.sort
# => [3]
# irb> arr.uniq.sort[-2]
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
