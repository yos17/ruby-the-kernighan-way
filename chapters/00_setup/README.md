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
- **NoMethodError** — you called a method on something that doesn't have it. Often `.something` on `nil`.

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
