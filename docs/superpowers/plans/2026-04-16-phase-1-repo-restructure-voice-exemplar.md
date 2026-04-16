# Phase 1 — Repo Restructure + Voice Exemplar (Ch 0 + Ch 1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move all 13 existing chapters to `archive/`, scaffold the new 14-chapter directory structure (`00_setup` through `13_shipping`), and write Ch 0 (Setup) + Ch 1 (Tutorial Introduction) end-to-end as voice exemplars that establish the tone for everything after.

**Architecture:** Foundation phase only — no content beyond Ch 0+1. The output is a repo where the current book is preserved verbatim under `archive/`, the new chapter scaffolding exists for all 14 future chapters (with empty placeholders), and Ch 0 + Ch 1 are written end-to-end (prose + runnable examples + exercise starter files + solutions). The user reviews the voice/quality of Ch 0+1 before Phase 2 starts; if voice misses, fix here before propagating to other chapters.

**Tech Stack:** Ruby 3.4, Git, Bash, Markdown.

**Spec reference:** `docs/superpowers/specs/2026-04-16-ruby-rails-kernighan-curriculum-design.md` — read it before starting.

---

## Task 1 — Archive existing chapters

**Files:**
- Move: `chapters/01_getting_started/` → `archive/chapters/01_getting_started/`
- Move: `chapters/02_types_and_expressions/` → `archive/chapters/02_types_and_expressions/`
- Move: `chapters/03_control_flow/` → `archive/chapters/03_control_flow/`
- Move: `chapters/04_methods_and_blocks/` → `archive/chapters/04_methods_and_blocks/`
- Move: `chapters/05_objects_and_classes/` → `archive/chapters/05_objects_and_classes/`
- Move: `chapters/06_modules_and_mixins/` → `archive/chapters/06_modules_and_mixins/`
- Move: `chapters/07_collections/` → `archive/chapters/07_collections/`
- Move: `chapters/08_io_and_files/` → `archive/chapters/08_io_and_files/`
- Move: `chapters/09_error_handling/` → `archive/chapters/09_error_handling/`
- Move: `chapters/10_metaprogramming/` → `archive/chapters/10_metaprogramming/`
- Move: `chapters/11_concurrency/` → `archive/chapters/11_concurrency/`
- Move: `chapters/12_gems_and_stdlib/` → `archive/chapters/12_gems_and_stdlib/`
- Move: `chapters/13_debugging/` → `archive/chapters/13_debugging/`
- Also move (as a unit): the duplicate `code/` directory → `archive/code/`
- Create: `archive/README.md`

- [ ] **Step 1: Create the archive directory structure**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
mkdir -p archive/chapters
```

Verify:

```bash
ls -d archive/chapters
# Expected: archive/chapters
```

- [ ] **Step 2: Move all 13 chapter directories into the archive**

Use plain `mv` so any untracked work-in-progress files (the user's drill solutions in `chapters/01_getting_started/*.rb` etc.) move with their chapters.

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
for dir in chapters/01_getting_started chapters/02_types_and_expressions \
           chapters/03_control_flow chapters/04_methods_and_blocks \
           chapters/05_objects_and_classes chapters/06_modules_and_mixins \
           chapters/07_collections chapters/08_io_and_files \
           chapters/09_error_handling chapters/10_metaprogramming \
           chapters/11_concurrency chapters/12_gems_and_stdlib \
           chapters/13_debugging; do
  mv "$dir" "archive/chapters/$(basename "$dir")"
done
```

Verify:

```bash
ls archive/chapters/
# Expected: 13 directories, 01_getting_started through 13_debugging
ls chapters/
# Expected: empty (or just .ruby-lsp/ if that exists)
```

- [ ] **Step 3: Move the duplicate `code/` directory into the archive**

The current repo has both `chapters/<n>/` AND a parallel `code/ch<NN>/` directory containing duplicate `.rb` files. Per the spec, the new layout has only `chapters/<n>/examples/`. Archive the old `code/`:

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
mv code archive/code
```

Verify:

```bash
ls archive/
# Expected: chapters  code
ls / | grep code
# (Should show nothing from the project root for `code`)
```

- [ ] **Step 4: Create `archive/README.md` explaining the archive**

Create `archive/README.md` with this exact content:

```markdown
# Archive — original draft of *Ruby: The Kernighan Way*

This directory preserves the original 13-chapter draft of the book unchanged. It is **frozen** — no edits, no deletions. Future chapters salvage material from it (see `docs/superpowers/specs/2026-04-16-ruby-rails-kernighan-curriculum-design.md` for the salvage plan), but the originals stay here as a reference.

## Contents

- `chapters/` — the original 13 chapters, each with the original `README.md` and any `.rb` files that were alongside it
- `code/` — a parallel directory with `ch01/`, `ch10/`, `ch13/` subdirectories holding earlier example code (duplicates of some files in `chapters/`)

## Why preserved

The new book under `chapters/` reuses many of the same example programs (calculator, BankAccount, Vector, etc.) but rewrites the prose for a beginner audience and reorganizes around the Kernighan-tools philosophy. Keeping the original draft intact lets us reference the previous wording and exercise design without losing it.
```

Save the file.

- [ ] **Step 5: Stage and commit the move**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
git add -A chapters/ archive/
git status
```

Expected git status: shows renames (or deletes + adds) for all 13 chapter `README.md` files and any tracked code files, plus new files for `archive/README.md` and the previously-untracked `.rb` files now under `archive/chapters/01_getting_started/` etc.

```bash
git commit -m "$(cat <<'EOF'
Move existing 13 chapters and code/ to archive/

Per the curriculum redesign spec
(docs/superpowers/specs/2026-04-16-ruby-rails-kernighan-curriculum-design.md),
the existing book is preserved unchanged in archive/chapters/ while the
new 14-chapter structure is built under chapters/.

Includes adding archive/README.md to explain the archived material.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"

git status
```

Expected: working tree clean (or only `chapters/` empty, no further untracked).

---

## Task 2 — Scaffold the new 14-chapter directory structure

**Files:**
- Create: 14 chapter directories under `chapters/`, each with placeholder README, examples/, exercises/, exercises/solutions/

- [ ] **Step 1: Create all 14 chapter directories with their subdirs**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way

CHAPTERS=(
  "00_setup"
  "01_tutorial"
  "02_strings_collections"
  "03_control_flow"
  "04_methods_blocks"
  "05_objects_classes"
  "06_metaprogramming"
  "07_files_errors_outside"
  "08_halfway_capstone"
  "09_building_a_gem"
  "10_tiny_framework"
  "11_real_rails_1"
  "12_real_rails_2"
  "13_shipping"
)

for ch in "${CHAPTERS[@]}"; do
  mkdir -p "chapters/$ch/examples" "chapters/$ch/exercises/solutions"
done
```

Verify:

```bash
ls chapters/
# Expected: 14 directories
ls chapters/05_objects_classes/
# Expected: examples  exercises
ls chapters/05_objects_classes/exercises/
# Expected: solutions
```

- [ ] **Step 2: Create placeholder READMEs for the 12 chapters that won't be written this phase**

For each chapter from `02_strings_collections` through `13_shipping`, create a placeholder `README.md` so the chapter directory isn't visually empty in the file tree.

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way

PLACEHOLDER_CHAPTERS=(
  "02_strings_collections:Strings, Numbers, Collections"
  "03_control_flow:Control Flow and Iteration"
  "04_methods_blocks:Methods, Blocks, Procedures"
  "05_objects_classes:Objects, Classes, Modules"
  "06_metaprogramming:Metaprogramming"
  "07_files_errors_outside:Files, Errors, the Outside World"
  "08_halfway_capstone:Halfway Capstone — a Real CLI Tool"
  "09_building_a_gem:Building a Gem"
  "10_tiny_framework:A Tiny Web Framework"
  "11_real_rails_1:Real Rails — Models, Controllers, Views"
  "12_real_rails_2:Real Rails — Hotwire, Forms, Auth, Jobs, Caching"
  "13_shipping:Shipping"
)

for entry in "${PLACEHOLDER_CHAPTERS[@]}"; do
  dir="${entry%%:*}"
  title="${entry#*:}"
  ch_num="${dir%%_*}"
  cat > "chapters/$dir/README.md" <<EOF
# Chapter $ch_num — $title

*This chapter is not yet written. See \`docs/superpowers/specs/2026-04-16-ruby-rails-kernighan-curriculum-design.md\` for the planned scope.*
EOF
done
```

Verify:

```bash
cat chapters/05_objects_classes/README.md
# Expected: heading "Chapter 05 — Objects, Classes, Modules" + the "not yet written" line
ls chapters/13_shipping/
# Expected: README.md  examples  exercises
```

- [ ] **Step 3: Add `.gitkeep` files to empty examples/ and exercises/ subdirs**

Empty directories aren't tracked by git. Add `.gitkeep` so the structure is preserved.

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way

for dir in chapters/*/examples chapters/*/exercises chapters/*/exercises/solutions; do
  touch "$dir/.gitkeep"
done
```

Verify:

```bash
ls chapters/13_shipping/examples/
# Expected: .gitkeep
ls chapters/13_shipping/exercises/solutions/
# Expected: .gitkeep
```

- [ ] **Step 4: Stage and commit the scaffolding**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
git add chapters/
git status
```

Expected: 14 chapter directories with placeholder READMEs and `.gitkeep` files staged.

```bash
git commit -m "$(cat <<'EOF'
Scaffold new 14-chapter directory structure

Creates chapters/00_setup/ through chapters/13_shipping/, each with
examples/, exercises/, and exercises/solutions/ subdirs. Twelve of the
fourteen READMEs are placeholders; Ch 0 and Ch 1 will be written in
the following commits as voice exemplars (per the Phase 1 plan in
docs/superpowers/plans/).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3 — Write Ch 0 (Setup)

**Files:**
- Create: `chapters/00_setup/README.md` (the chapter prose, ~10 pages)
- Create: `chapters/00_setup/examples/hello.rb` (the one-line first program)
- Create: `chapters/00_setup/exercises/1_greet_yourself.rb` (starter)
- Create: `chapters/00_setup/exercises/2_goodbye.rb` (starter)
- Create: `chapters/00_setup/exercises/3_break_things.rb` (starter)
- Create: `chapters/00_setup/exercises/solutions/1_greet_yourself.rb` (solution)
- Create: `chapters/00_setup/exercises/solutions/2_goodbye.rb` (solution)
- Create: `chapters/00_setup/exercises/solutions/3_break_things.rb` (solution)
- Delete: `chapters/00_setup/.gitkeep` files in examples/ and exercises/ (real files now exist)

- [ ] **Step 1: Write `chapters/00_setup/README.md`**

Replace the file with this exact content:

````markdown
# Chapter 0 — Setup

Before you write Ruby, you need three things on your computer: Ruby itself, a code editor, and a terminal. This chapter installs them and runs your first program. About thirty minutes if it all works the first time, longer if something breaks.

## Installing Ruby

Ruby runs on macOS, Linux, and Windows. The install method differs by platform.

### macOS

The Ruby that ships with macOS is too old. Use a version manager instead. The simplest is `mise`:

```bash
curl https://mise.run | sh
mise use --global ruby@3.4
```

Restart your terminal and verify:

```bash
ruby --version
# => ruby 3.4.x ...
```

If `mise` won't install, try `rbenv`:

```bash
brew install rbenv
rbenv install 3.4.0
rbenv global 3.4.0
```

### Linux (Ubuntu/Debian)

```bash
curl https://mise.run | sh
mise use --global ruby@3.4
```

Same verification:

```bash
ruby --version
```

### Windows

Use the official installer at `https://rubyinstaller.org/`. Download the version with DevKit (named like `Ruby+Devkit 3.4.x-y (x64)`) and run the installer. Accept the defaults. When asked, install MSYS2 and the development toolchain.

Open a new Command Prompt and verify:

```cmd
ruby --version
```

### What you just installed

Three programs:

- `ruby` — the interpreter. Run files with `ruby file.rb`.
- `gem` — the package installer. Used to add libraries.
- `irb` — an interactive Ruby shell. Type Ruby in, see results immediately.

You won't need to install anything else for the first eight chapters.

## Installing VS Code

Download VS Code from `https://code.visualstudio.com/` and install it like any other application.

Open it. From the Extensions panel (Cmd+Shift+X on macOS, Ctrl+Shift+X elsewhere), install `Shopify.ruby-lsp`. This is the official Ruby language extension. It gives you syntax highlighting, autocomplete, and inline error detection.

You can use a different editor if you have a favorite — Sublime Text, Vim, Cursor, RubyMine. The book uses VS Code in screenshots, but the code is the same.

## Just-enough terminal

You'll spend a lot of time in the terminal. Here are the commands you need today.

```bash
pwd            # print working directory — where am I?
ls             # list files in this directory
cd folder      # change into a folder
cd ..          # go up one folder
cd ~           # go to your home directory
mkdir name     # make a new folder
```

Tab completion saves typing. Start typing a path and press Tab — the terminal completes it.

Up arrow recalls previous commands. Ctrl+C cancels what's running. Ctrl+D exits an interactive shell.

## Your first program

Make a folder for the book's code:

```bash
cd ~
mkdir ruby-book
cd ruby-book
```

Create a file `hello.rb` (in VS Code: File → New File, save as `hello.rb` in the `ruby-book` folder you just made).

Type one line:

```ruby
puts "Hello, World!"
```

Save the file. In the terminal, while in the `ruby-book` folder:

```bash
ruby hello.rb
# => Hello, World!
```

That's a Ruby program. The interpreter (`ruby`) read your file (`hello.rb`), executed it top to bottom, and printed the result.

A copy of `hello.rb` is in `examples/` next to this chapter — but typing it yourself once is the point.

## When things go wrong

Programs crash. Reading the crash is half the skill.

Edit `hello.rb` to break it:

```ruby
puts Hello, World!
```

(Removed the quotes.) Run it:

```bash
ruby hello.rb
```

You'll see something like:

```
hello.rb:1: syntax error, unexpected ',', expecting `end' or dummy end
puts Hello, World!
            ^
```

Three things to read:

- **The file and line number**: `hello.rb:1` — the error is at line 1 of `hello.rb`.
- **The error type**: `syntax error` — the program isn't valid Ruby.
- **The pointer**: `^` shows where Ruby got confused.

The `^` is at `World!`. Ruby was happy until it saw `World!` without quotes, expecting a different keyword. Put the quotes back:

```ruby
puts "Hello, World!"
```

Re-run: works.

Three error types you'll see often:

- **Syntax error** — your code isn't valid Ruby. Look for typos near the `^`.
- **NameError** — you used a name Ruby doesn't recognize. Misspelled variable or undefined method.
- **NoMethodError** — you called a method on something that doesn't have it. Often `.something on nil`.

When stuck, copy the first line of the error into a search engine. Almost any Ruby error you'll hit in the first ten chapters has been hit by ten thousand other beginners; the answers are out there.

## What you learned

| Concept | Key point |
|---|---|
| `ruby file.rb` | runs a Ruby program |
| `puts` | prints with a newline |
| `irb` | interactive Ruby — try things without a file |
| Syntax error | Ruby couldn't parse your file. Look near the `^`. |
| NameError | undefined name. Misspelled? |
| NoMethodError | called a method on the wrong kind of value (often `nil`). |
| Tab completion | press Tab to complete file paths in the terminal |

## Exercises

1. Make `hello.rb` greet you by name instead: `puts "Hello, Yosia!"` (use your real name). Run it. Starter: `exercises/1_greet_yourself.rb`.

2. Make a second program `goodbye.rb` that prints `Goodbye!`. Run it. Starter: `exercises/2_goodbye.rb`.

3. Break `hello.rb` deliberately three different ways: remove a quote, misspell `puts`, add a stray `(`. Run each version, read the error, fix it. Starter: `exercises/3_break_things.rb`.

Solutions are in `exercises/solutions/`. Look at them only after you've tried.
````

Save the file.

- [ ] **Step 2: Write `chapters/00_setup/examples/hello.rb`**

```ruby
puts "Hello, World!"
```

Save the file. Verify:

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
ruby chapters/00_setup/examples/hello.rb
# Expected: Hello, World!
```

- [ ] **Step 3: Write the three exercise starter files**

Create `chapters/00_setup/exercises/1_greet_yourself.rb`:

```ruby
# Exercise 1 — Greet yourself by name
#
# Modify this file so that running it prints a greeting with your real name.
# Example output (with your name):
#   Hello, Yosia!

# TODO: change "World" to your name
puts "Hello, World!"
```

Create `chapters/00_setup/exercises/2_goodbye.rb`:

```ruby
# Exercise 2 — Write a goodbye program
#
# This file should print:
#   Goodbye!
#
# Then run it with:  ruby chapters/00_setup/exercises/2_goodbye.rb

# TODO: write your puts line below
```

Create `chapters/00_setup/exercises/3_break_things.rb`:

```ruby
# Exercise 3 — Break this program three different ways
#
# 1. Remove the quotes around "Hello, World!" — note the syntax error.
# 2. Restore the quotes, but misspell `puts` (try `put`) — note the NameError or NoMethodError.
# 3. Restore `puts`, but add a stray `(` after it — note the syntax error.
#
# Run after each break:
#   ruby chapters/00_setup/exercises/3_break_things.rb
#
# Read the error message each time. Notice how the file:line and the `^` arrow
# point you at the problem.

puts "Hello, World!"
```

- [ ] **Step 4: Write the three exercise solution files**

Create `chapters/00_setup/exercises/solutions/1_greet_yourself.rb`:

```ruby
# Solution to Exercise 1
puts "Hello, Yosia!"
```

Create `chapters/00_setup/exercises/solutions/2_goodbye.rb`:

```ruby
# Solution to Exercise 2
puts "Goodbye!"
```

Create `chapters/00_setup/exercises/solutions/3_break_things.rb`:

```ruby
# Solution to Exercise 3 — the FIXED version after all three breaks were repaired.
# (The point of the exercise is to break it; here is the unbroken state.)
puts "Hello, World!"
```

- [ ] **Step 5: Verify all Ch 0 example and solution files run**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way

ruby chapters/00_setup/examples/hello.rb
# Expected: Hello, World!

ruby chapters/00_setup/exercises/solutions/1_greet_yourself.rb
# Expected: Hello, Yosia!

ruby chapters/00_setup/exercises/solutions/2_goodbye.rb
# Expected: Goodbye!

ruby chapters/00_setup/exercises/solutions/3_break_things.rb
# Expected: Hello, World!
```

- [ ] **Step 6: Remove the .gitkeep files in chapters/00_setup/ now that real files exist**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
rm chapters/00_setup/examples/.gitkeep
rm chapters/00_setup/exercises/.gitkeep
rm chapters/00_setup/exercises/solutions/.gitkeep
```

- [ ] **Step 7: Stage and commit Ch 0**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
git add chapters/00_setup/
git status
```

Expected: README.md plus 1 example file plus 3 exercise starters plus 3 solutions; the three .gitkeep deletions also staged.

```bash
git commit -m "$(cat <<'EOF'
Write Ch 0 — Setup

Voice-exemplar chapter: install Ruby, install VS Code, just-enough
terminal commands, run hello.rb, read errors. Ten pages of dense
prose with three exercises (greet yourself, goodbye, break things).

This chapter sets the tone for the rest of the book: terse direct
prose, code first then explanation, output examples for every code
block, no callouts/emoji. Ch 1 follows in the next commit.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4 — Write Ch 1 README (the chapter prose)

**Files:**
- Create: `chapters/01_tutorial/README.md` (the chapter prose, ~25 pages)

- [ ] **Step 1: Replace the placeholder `chapters/01_tutorial/README.md` with the full chapter**

Write this exact content to `chapters/01_tutorial/README.md`:

````markdown
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
````

Save the file.

- [ ] **Step 2: Verify the README renders correctly**

Open the file in any markdown viewer (or just `cat` it) and check:

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
wc -l chapters/01_tutorial/README.md
# Expected: roughly 200-250 lines
head -20 chapters/01_tutorial/README.md
# Expected: starts with "# Chapter 1 — A Tutorial Introduction"
grep -c '```' chapters/01_tutorial/README.md
# Expected: an even number (every code block opens and closes)
```

- [ ] **Step 3: Commit the README only (examples and exercises in next tasks)**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
git add chapters/01_tutorial/README.md
git commit -m "$(cat <<'EOF'
Write Ch 1 README — A Tutorial Introduction

The first content chapter. Voice exemplar: terse Kernighan-style
prose, three programs (hello.rb expanded, calc.rb, tiny_processor.rb),
concepts emerging through the build, output examples after every code
block, six exercises at the end.

Concepts established: variables, string interpolation, gets/chomp,
ARGV, type conversion, case/when (with else), if-modifier, methods,
file iteration with blocks, +=.

Example .rb files and exercise starters/solutions are added in the
next two commits.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5 — Write Ch 1 example programs

**Files:**
- Create: `chapters/01_tutorial/examples/hello.rb`
- Create: `chapters/01_tutorial/examples/calc.rb`
- Create: `chapters/01_tutorial/examples/tiny_processor.rb`
- Create: `chapters/01_tutorial/examples/notes.txt`
- Delete: `chapters/01_tutorial/examples/.gitkeep`

- [ ] **Step 1: Write `chapters/01_tutorial/examples/hello.rb`**

This is the final form (with `gets.chomp`):

```ruby
# hello.rb — interactive greeter
# Usage: ruby hello.rb

print "What is your name? "
name = gets.chomp
puts "Hello, #{name}!"
```

- [ ] **Step 2: Write `chapters/01_tutorial/examples/calc.rb`**

The extracted-method version:

```ruby
# calc.rb — a calculator that takes two numbers and an operator from ARGV
# Usage: ruby calc.rb <a> <op> <b>
#   ruby calc.rb 10 + 5    # => 15.0
#   ruby calc.rb 10 / 4    # => 2.5
#   ruby calc.rb 10 / 0    # => Cannot divide by zero
#   ruby calc.rb 10 % 5    # => Unknown operator: %

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

- [ ] **Step 3: Write `chapters/01_tutorial/examples/tiny_processor.rb`**

The lines + words + chars version:

```ruby
# tiny_processor.rb — count lines, words, and characters in a file
# Usage: ruby tiny_processor.rb <filename>
#   ruby tiny_processor.rb notes.txt

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

- [ ] **Step 4: Write `chapters/01_tutorial/examples/notes.txt`**

Plain-text test data for `tiny_processor.rb`:

```
First line
Second line
Third line
```

(Three lines exactly. No trailing blank line.)

- [ ] **Step 5: Delete the `.gitkeep` from examples/**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
rm chapters/01_tutorial/examples/.gitkeep
```

- [ ] **Step 6: Verify all examples run as expected**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way

# hello.rb expects interactive input — pipe a name in:
echo "Yosia" | ruby chapters/01_tutorial/examples/hello.rb
# Expected: "What is your name? Hello, Yosia!"

ruby chapters/01_tutorial/examples/calc.rb 10 + 5
# Expected: 15.0

ruby chapters/01_tutorial/examples/calc.rb 10 / 0
# Expected: Cannot divide by zero

ruby chapters/01_tutorial/examples/calc.rb 10 % 5
# Expected: Unknown operator: %

ruby chapters/01_tutorial/examples/tiny_processor.rb chapters/01_tutorial/examples/notes.txt
# Expected: 3 lines, 6 words, 34 characters
# (Assumes notes.txt ends with a normal POSIX trailing newline. If the
#  editor saved without one, you'd see 33 characters — fix the editor
#  setting rather than the file, since most tooling expects trailing
#  newlines.)
```

If any output differs, fix the example file before committing.

- [ ] **Step 7: Stage and commit the examples**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
git add chapters/01_tutorial/examples/
git commit -m "$(cat <<'EOF'
Add Ch 1 example programs

hello.rb (interactive greeter), calc.rb (extracted-method calculator
with case/when, error handling for divide-by-zero, unknown-operator
default), tiny_processor.rb (lines/words/chars counter), and
notes.txt (test data for tiny_processor.rb).

All four files match the listings in chapters/01_tutorial/README.md
and have been verified to run against the expected outputs in the
README.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6 — Write Ch 1 exercise starters and solutions

**Files:**
- Create: `chapters/01_tutorial/exercises/1_hello_with_greeting.rb`
- Create: `chapters/01_tutorial/exercises/2_calc_power_modulo.rb`
- Create: `chapters/01_tutorial/exercises/3_calc_usage_message.rb`
- Create: `chapters/01_tutorial/exercises/4_processor_multiple_files.rb`
- Create: `chapters/01_tutorial/exercises/5_processor_stdin.rb`
- Create: `chapters/01_tutorial/exercises/6_echo.rb`
- Create: `chapters/01_tutorial/exercises/solutions/{1..6}_*.rb` (matching solutions)
- Delete: `chapters/01_tutorial/exercises/.gitkeep`, `chapters/01_tutorial/exercises/solutions/.gitkeep`

- [ ] **Step 1: Write the six exercise starter files**

Create `chapters/01_tutorial/exercises/1_hello_with_greeting.rb`:

```ruby
# Exercise 1 — hello.rb with a time-of-day greeting
#
# Extend hello.rb to accept name AND time-of-day as arguments.
# Examples:
#   ruby exercises/1_hello_with_greeting.rb Yosia morning   # => Good morning, Yosia!
#   ruby exercises/1_hello_with_greeting.rb Yosia afternoon # => Good afternoon, Yosia!
#   ruby exercises/1_hello_with_greeting.rb Yosia evening   # => Good evening, Yosia!
#   ruby exercises/1_hello_with_greeting.rb Yosia           # => Hello, Yosia!  (no time given)
#
# Hint: ARGV[0] is the name, ARGV[1] is the time. Use case/when on the time.

name = ARGV[0]
time = ARGV[1]

# TODO: build the greeting string based on `time`
# TODO: handle the case where `time` is nil (no second argument)
# TODO: print the greeting
```

Create `chapters/01_tutorial/exercises/2_calc_power_modulo.rb`:

```ruby
# Exercise 2 — calc.rb with ** (power) and % (modulo)
#
# Add support for two new operators to the calculator:
#   ruby exercises/2_calc_power_modulo.rb 2 ** 10   # => 1024.0
#   ruby exercises/2_calc_power_modulo.rb 17 % 5    # => 2.0
#
# Existing operators (+ - * /) should still work.

def calculate(a, op, b)
  case op
  when "+" then a + b
  when "-" then a - b
  when "*" then a * b
  when "/"
    return "Cannot divide by zero" if b == 0
    a / b
  # TODO: add a `when "**"` branch
  # TODO: add a `when "%"` branch
  else
    "Unknown operator: #{op}"
  end
end

a  = ARGV[0].to_f
op = ARGV[1]
b  = ARGV[2].to_f

puts calculate(a, op, b)
```

Create `chapters/01_tutorial/exercises/3_calc_usage_message.rb`:

```ruby
# Exercise 3 — calc.rb usage message
#
# When ARGV doesn't have exactly three items, print a usage message and exit.
# Examples:
#   ruby exercises/3_calc_usage_message.rb              # => Usage: ruby calc.rb <a> <op> <b>  (then exits)
#   ruby exercises/3_calc_usage_message.rb 10 +         # => Usage: ruby calc.rb <a> <op> <b>  (then exits)
#   ruby exercises/3_calc_usage_message.rb 10 + 5       # => 15.0  (works as before)
#
# Hint: `ARGV.length` and `exit 1` (the 1 means "non-zero exit code = error").

# TODO: check ARGV.length, print usage and exit if wrong
# TODO: then do the normal calculation
```

Create `chapters/01_tutorial/exercises/4_processor_multiple_files.rb`:

```ruby
# Exercise 4 — tiny_processor.rb with multiple files
#
# Accept multiple filenames. Print one line per file with its individual
# counts, then a total line.
# Example:
#   ruby exercises/4_processor_multiple_files.rb a.txt b.txt
#   #=> a.txt: 3 lines, 6 words, 33 characters
#   #=> b.txt: 5 lines, 12 words, 80 characters
#   #=> total: 8 lines, 18 words, 113 characters
#
# Hint: ARGV.each do |filename| ... end. Track running totals outside the loop.

# TODO: initialize total_lines, total_words, total_chars
# TODO: ARGV.each do |filename| ... per-file counts ... add to totals ... end
# TODO: print the total line at the end
```

Create `chapters/01_tutorial/exercises/5_processor_stdin.rb`:

```ruby
# Exercise 5 — tiny_processor.rb that reads stdin when no files given
#
# When ARGV is empty, read from STDIN instead of a file.
# Example:
#   cat notes.txt | ruby exercises/5_processor_stdin.rb
#   #=> 3 lines, 6 words, 33 characters
#
# When ARGV has filenames, behave like the original tiny_processor.rb.
#
# Hint: STDIN.each_line do |line| ... end iterates stdin lines.

lines = 0
words = 0
chars = 0

if ARGV.empty?
  # TODO: iterate STDIN.each_line, count lines/words/chars
else
  # TODO: iterate ARGV.each, opening each file with File.foreach
end

puts "#{lines} lines, #{words} words, #{chars} characters"
```

Create `chapters/01_tutorial/exercises/6_echo.rb`:

```ruby
# Exercise 6 — echo.rb
#
# Print each command-line argument on its own line, numbered (1-based).
# Example:
#   ruby exercises/6_echo.rb one two three
#   #=> 1: one
#   #=> 2: two
#   #=> 3: three
#
# When no arguments are given, print a usage message and exit 1.
#
# Hint: ARGV.each_with_index do |arg, i| ... end, but i is 0-based.

# TODO: usage check
# TODO: iterate ARGV with index, print "n: word" per arg
```

- [ ] **Step 2: Write the six solution files**

Create `chapters/01_tutorial/exercises/solutions/1_hello_with_greeting.rb`:

```ruby
# Solution to Exercise 1
name = ARGV[0]
time = ARGV[1]

greeting = case time
           when "morning"   then "Good morning"
           when "afternoon" then "Good afternoon"
           when "evening"   then "Good evening"
           else                  "Hello"
           end

puts "#{greeting}, #{name}!"
```

Create `chapters/01_tutorial/exercises/solutions/2_calc_power_modulo.rb`:

```ruby
# Solution to Exercise 2
def calculate(a, op, b)
  case op
  when "+"  then a + b
  when "-"  then a - b
  when "*"  then a * b
  when "**" then a ** b
  when "%"  then a % b
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

Create `chapters/01_tutorial/exercises/solutions/3_calc_usage_message.rb`:

```ruby
# Solution to Exercise 3
if ARGV.length != 3
  puts "Usage: ruby calc.rb <a> <op> <b>"
  exit 1
end

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

Create `chapters/01_tutorial/exercises/solutions/4_processor_multiple_files.rb`:

```ruby
# Solution to Exercise 4
total_lines = 0
total_words = 0
total_chars = 0

ARGV.each do |filename|
  lines = 0
  words = 0
  chars = 0

  File.foreach(filename) do |line|
    lines += 1
    words += line.split.length
    chars += line.length
  end

  puts "#{filename}: #{lines} lines, #{words} words, #{chars} characters"

  total_lines += lines
  total_words += words
  total_chars += chars
end

puts "total: #{total_lines} lines, #{total_words} words, #{total_chars} characters"
```

Create `chapters/01_tutorial/exercises/solutions/5_processor_stdin.rb`:

```ruby
# Solution to Exercise 5
lines = 0
words = 0
chars = 0

count = ->(line) {
  lines += 1
  words += line.split.length
  chars += line.length
}

if ARGV.empty?
  STDIN.each_line(&count)
else
  ARGV.each do |filename|
    File.foreach(filename, &count)
  end
end

puts "#{lines} lines, #{words} words, #{chars} characters"
```

Create `chapters/01_tutorial/exercises/solutions/6_echo.rb`:

```ruby
# Solution to Exercise 6
if ARGV.empty?
  puts "Usage: ruby echo.rb arg1 arg2 ..."
  exit 1
end

ARGV.each_with_index do |arg, i|
  puts "#{i + 1}: #{arg}"
end
```

- [ ] **Step 3: Delete the .gitkeep files in chapters/01_tutorial/exercises/**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
rm chapters/01_tutorial/exercises/.gitkeep
rm chapters/01_tutorial/exercises/solutions/.gitkeep
```

- [ ] **Step 4: Verify every solution runs and matches the spec in the README**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way

ruby chapters/01_tutorial/exercises/solutions/1_hello_with_greeting.rb Yosia morning
# Expected: Good morning, Yosia!

ruby chapters/01_tutorial/exercises/solutions/1_hello_with_greeting.rb Yosia
# Expected: Hello, Yosia!

ruby chapters/01_tutorial/exercises/solutions/2_calc_power_modulo.rb 2 '**' 10
# Expected: 1024.0
# (note the quotes around **; the shell otherwise globs it)

ruby chapters/01_tutorial/exercises/solutions/2_calc_power_modulo.rb 17 '%' 5
# Expected: 2.0

ruby chapters/01_tutorial/exercises/solutions/3_calc_usage_message.rb 2>&1
# Expected: Usage: ruby calc.rb <a> <op> <b>
# (and exit code 1)

ruby chapters/01_tutorial/exercises/solutions/3_calc_usage_message.rb 10 + 5
# Expected: 15.0

# For exercise 4, make a second test file:
echo -e "alpha beta gamma\ndelta epsilon\nzeta eta theta iota" > /tmp/b.txt
ruby chapters/01_tutorial/exercises/solutions/4_processor_multiple_files.rb chapters/01_tutorial/examples/notes.txt /tmp/b.txt
# Expected output (3 lines, then total):
#   chapters/01_tutorial/examples/notes.txt: 3 lines, 6 words, 34 characters
#   /tmp/b.txt: 3 lines, 9 words, 51 characters
#   total: 6 lines, 15 words, 85 characters

cat chapters/01_tutorial/examples/notes.txt | ruby chapters/01_tutorial/exercises/solutions/5_processor_stdin.rb
# Expected: 3 lines, 6 words, 34 characters

ruby chapters/01_tutorial/exercises/solutions/5_processor_stdin.rb chapters/01_tutorial/examples/notes.txt
# Expected: 3 lines, 6 words, 34 characters

ruby chapters/01_tutorial/exercises/solutions/6_echo.rb one two three
# Expected:
#   1: one
#   2: two
#   3: three

ruby chapters/01_tutorial/exercises/solutions/6_echo.rb 2>&1
# Expected: Usage: ruby echo.rb arg1 arg2 ...

# Cleanup
rm /tmp/b.txt
```

If any output differs from expected, fix the solution file before committing.

- [ ] **Step 5: Stage and commit exercises + solutions**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
git add chapters/01_tutorial/exercises/
git commit -m "$(cat <<'EOF'
Add Ch 1 exercises and solutions

Six exercises (one per program theme): hello with time-of-day
greeting, calc with ** and %, calc with usage message, processor
with multiple files, processor with stdin, echo.rb. Each has a
starter file with TODO markers and a separate solution file in
exercises/solutions/.

All six solutions verified to produce the expected output in the
README.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7 — Update top-level README.md

**Files:**
- Modify: `README.md` (rewrite the chapter index and intro to match the new 14-chapter shape)

- [ ] **Step 1: Rewrite `README.md` with the new structure**

Replace the entire contents of `README.md` with:

```markdown
# Ruby & Rails — The Kernighan Way

A tutorial book that takes a beginner from "I just installed Ruby" to "I can build a tiny Rails framework, ship a gem, and deploy a real Rails app." Designed for the reader who wants to *understand* Ruby — not just use Rails.

The book is for someone comfortable using a computer who has not programmed before. It is not for someone who already writes Ruby comfortably; for that, the existing 13-chapter draft preserved in [`archive/`](./archive/) is more useful.

## Why "Kernighan Way"

Brian Kernighan's books teach by building. You learn C in *K&R* by writing tools — `wc`, `grep`, a calculator, a text formatter. You learn Unix in *The UNIX Programming Environment* by writing shell pipelines and a calculator language. The programs accumulate; later programs use earlier ones.

This book follows the same shape. Every chapter builds 2-3 working programs. The TOC reads like a list of files in `bin/`, not a list of language features.

## What you'll build

| Chapter | What you build |
|---|---|
| 0 | Setup: install Ruby, run your first file |
| 1 | A greeter, a calculator, a tiny line counter |
| 2 | A histogram, a CSV summarizer, a word-frequency counter |
| 3 | A `grep` clone, a top-errors log analyzer |
| 4 | A pipeline composer, a memoizer, a tiny event bus |
| 5 | An address book, an animal shelter, a plugin loader |
| 6 | Your own `attr_accessor`, a flexible-hash, a tiny DSL |
| 7 | A log watcher, a JSON config loader, a tiny HTTP client |
| 8 | **Halfway capstone**: a complete personal task tracker CLI |
| 9 | Build and publish a gem to RubyGems |
| 10 | **A tiny web framework** — Rack, router, ORM, renderer, composed |
| 11 | A real Rails app: blog with comments (Active Record, controllers, views) |
| 12 | The same blog with Hotwire, forms, auth, jobs, caching |
| 13 | Deploy your blog to a real host with Kamal |

## Setup

```bash
ruby --version    # Ruby 3.4 or newer
```

If you don't have Ruby, start with [Chapter 0](./chapters/00_setup/).

## How to read

Read sequentially. Each chapter assumes the previous ones. Type the example programs yourself — don't just read them. Try the exercises before looking at the solutions.

The book uses `chapters/<NN>_<name>/` for each chapter:

```
chapters/01_tutorial/
├── README.md          # the chapter prose
├── examples/          # the programs the chapter builds
└── exercises/
    ├── 1_*.rb         # exercise starter files
    └── solutions/     # solutions, kept separate so you actually try
```

## Status

Currently being rewritten from a 13-chapter draft (preserved in `archive/`) into the 14-chapter book described above. As of this commit:

- **Ch 0 — Setup** ✅ written
- **Ch 1 — A Tutorial Introduction** ✅ written
- **Ch 2-13** ⏳ scaffolded but not yet written

## License

(to be decided)
```

Save the file.

- [ ] **Step 2: Verify**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
head -5 README.md
# Expected: starts with "# Ruby & Rails — The Kernighan Way"
grep -c "Chapter" README.md
# Expected: at least 14 (one per chapter row + headings)
```

- [ ] **Step 3: Stage and commit**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way
git add README.md
git commit -m "$(cat <<'EOF'
Rewrite top-level README for the new 14-chapter book

New audience framing (computer-comfortable beginner, not "knows
another language"). New chapter index covering all 14 chapters,
with status markers showing Ch 0 + Ch 1 written and Ch 2-13
scaffolded but not yet written. Points readers at archive/ for
the original draft.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8 — Final verification + summary commit

- [ ] **Step 1: Verify the repo state matches what Phase 1 was supposed to deliver**

```bash
cd /Users/yosia/Desktop/learn/ruby/ruby-the-kernighan-way

# 1. Archive contains all 13 original chapters
ls archive/chapters/ | wc -l
# Expected: 13
ls archive/code/ | wc -l
# Expected: at least 3 (ch01, ch10, ch13)

# 2. New chapters/ has 14 directories
ls chapters/ | wc -l
# Expected: 14

# 3. Ch 0 has README + 1 example + 3 exercises + 3 solutions
ls chapters/00_setup/
ls chapters/00_setup/examples/
ls chapters/00_setup/exercises/
ls chapters/00_setup/exercises/solutions/

# 4. Ch 1 has README + 4 examples + 6 exercises + 6 solutions
ls chapters/01_tutorial/
ls chapters/01_tutorial/examples/      # Expected: hello.rb calc.rb tiny_processor.rb notes.txt
ls chapters/01_tutorial/exercises/     # Expected: 1_*.rb 2_*.rb ... 6_*.rb solutions/
ls chapters/01_tutorial/exercises/solutions/

# 5. Other chapters have placeholder README + .gitkeep stubs
cat chapters/05_objects_classes/README.md
ls chapters/05_objects_classes/examples/     # Expected: .gitkeep
ls chapters/05_objects_classes/exercises/    # Expected: solutions  .gitkeep
ls chapters/05_objects_classes/exercises/solutions/  # Expected: .gitkeep

# 6. Top-level README mentions the new chapter index
head -30 README.md

# 7. Git log shows the Phase 1 sequence of commits
git log --oneline | head -10
# Expected (recent first):
#   <hash> Rewrite top-level README for the new 14-chapter book
#   <hash> Add Ch 1 exercises and solutions
#   <hash> Add Ch 1 example programs
#   <hash> Write Ch 1 README — A Tutorial Introduction
#   <hash> Write Ch 0 — Setup
#   <hash> Scaffold new 14-chapter directory structure
#   <hash> Move existing 13 chapters and code/ to archive/
#   <hash> Add curriculum redesign spec — Kernighan-style Ruby + Rails
#   ... earlier commits ...

# 8. No untracked files in chapters/ or archive/
git status
# Expected: working tree clean
```

If any check fails, find the gap and add a fix-up commit referencing the failing check.

- [ ] **Step 2: (Optional) Push to origin if user wants — DO NOT push without asking**

This step is intentionally not automated. Phase 1 produces seven commits ahead of `origin/main`. The user should decide whether to push them. If they say "push," run:

```bash
git push origin main
```

Otherwise, leave them local and tell the user what's queued.

---

## Self-review checklist (run after Task 8)

- [ ] Every spec section in `docs/superpowers/specs/2026-04-16-ruby-rails-kernighan-curriculum-design.md` Phase 1 row is delivered (archive move + scaffold + Ch 0 + Ch 1).
- [ ] Every code block in `chapters/01_tutorial/README.md` has a matching `.rb` file in `examples/` or `exercises/`.
- [ ] Every exercise listed in the README has both a starter and a solution file.
- [ ] Voice in Ch 0 and Ch 1 is consistent — terse, no "let's", no callout boxes, no emoji.
- [ ] Each example and solution file has a top-of-file comment explaining what it is and how to run it.
- [ ] Modern Ruby idioms used naturally (string interpolation in Ch 1, `case/when` in calc.rb solutions, lambda + `&` in exercise 5 solution).
- [ ] All commits are atomic (one task ≈ one commit) and have descriptive messages.

If any check fails, fix it. No need to re-review the whole plan — just fix and move on.

---

## What this plan does NOT do

This is **only Phase 1** of the curriculum redesign. After this phase ships:

- **Phase 2 plan** is needed for Ch 2-4 (Strings/Numbers/Collections, Control Flow, Methods/Blocks).
- **Phase 3 plan** for Ch 5-6 (Objects/Classes, Metaprogramming).
- **Phase 4 plan** for Ch 7-9 (I/O, halfway capstone, gem authoring).
- **Phase 5 plan** for Ch 10 (the tiny web framework — gets its own focused plan).
- **Phase 6 plan** for Ch 11-12 (Real Rails).
- **Phase 7 plan** for Ch 13 (Shipping) + final copyedit pass.

After Phase 1 finishes, get user feedback on Ch 0 + Ch 1 voice before starting Phase 2 — this is the explicit "user reviews voice exemplar" gate from the spec.
