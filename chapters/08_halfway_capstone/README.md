# Chapter 8 — Halfway Capstone: a Real CLI Tool

You've got the Ruby toolkit. This chapter combines it all into one working program: `tasks`, a personal task tracker. It composes techniques from the previous seven chapters — file I/O and JSON (Ch 7), classes and Enumerable (Ch 5), method_missing-flavored dispatch (Ch 6), Enumerable methods (Ch 2-3), and exception handling (Ch 7). The goal is not a new concept, but the experience of writing a non-trivial program where everything you've learned earns its keep.

## What `tasks` does

```
$ tasks add "buy milk"                    # adds a task
$ tasks add "study Ruby" --due 2026-04-30 # with due date
$ tasks list                              # shows all open tasks
$ tasks list --done                       # shows completed
$ tasks done 2                            # mark task #2 done
$ tasks search milk                       # filter by keyword
$ tasks stats                             # summary
$ tasks export csv > out.csv              # export
```

Tasks live in a JSON file (`~/.tasks.json` by default, or wherever `TASKS_FILE` env var points).

## The shape

Two layers:

- **`TaskStore`** — the data layer. Loads/saves JSON, knows about `Task` objects, provides `add`, `find`, `update`, `each`. Doesn't know about CLI.
- **`CLI`** — the interface layer. Parses ARGV, dispatches to `TaskStore` methods, formats output. Doesn't know about JSON.

This is the *hexagonal* shape applied to a 200-line program. The CLI could be replaced by a web interface and the data layer wouldn't change.

## Task — the value object

```ruby
Task = Data.define(:id, :text, :due, :done) do
  def to_h = { id: id, text: text, due: due, done: done }
  def overdue? = due && !done && Date.parse(due) < Date.today
end
```

`Data.define` (Ch 5) gives us value equality and immutability. The block adds methods. `to_h` for serialization, `overdue?` for the display.

## TaskStore — the data layer

```ruby
class TaskStore
  include Enumerable

  def initialize(path)
    @path = path
    @tasks = load
  end

  def add(text, due: nil)
    next_id = (@tasks.map(&:id).max || 0) + 1
    task = Task.new(id: next_id, text: text, due: due, done: false)
    @tasks << task
    save
    task
  end

  def find(id)
    @tasks.find { |t| t.id == id } or raise NotFound, "no task with id #{id}"
  end

  def mark_done(id)
    task = find(id)
    @tasks[@tasks.index(task)] = Task.new(**task.to_h, done: true)
    save
    @tasks[@tasks.index { |t| t.id == id }]
  end

  def each(&block) = @tasks.each(&block)

  class NotFound < StandardError; end

  private

  def load
    return [] unless File.exist?(@path)
    JSON.parse(File.read(@path), symbolize_names: true).map { |h| Task.new(**h) }
  rescue JSON::ParserError
    warn "warning: could not parse #{@path}; starting fresh"
    []
  end

  def save
    File.write(@path, JSON.pretty_generate(@tasks.map(&:to_h)))
  end
end
```

What to notice.

`include Enumerable` + a `each` method — and we get `count`, `select`, `map`, `group_by`, `tally` for free. We use them in the CLI.

`@tasks[@tasks.index(task)] = Task.new(**task.to_h, done: true)` — Data instances are immutable, so we replace the task in the array with a new one. `**task.to_h` splats the hash as keyword arguments; the explicit `done: true` overrides the splatted value.

`load` uses `rescue JSON::ParserError` — if the file is corrupted, warn and start fresh. This is intentionally permissive; for real apps you'd probably exit with a clear error.

## CLI — the interface layer

```ruby
class CLI
  COMMANDS = %i[add list done search stats export help]

  def initialize(store, out: $stdout)
    @store = store
    @out   = out
  end

  def run(args)
    cmd = args.shift&.to_sym
    cmd = :help unless COMMANDS.include?(cmd)
    public_send(cmd, args)
  rescue TaskStore::NotFound => e
    @out.puts "error: #{e.message}"
    exit 1
  end

  def add(args)
    text, due = parse_add_args(args)
    abort "usage: tasks add TEXT [--due YYYY-MM-DD]" unless text
    task = @store.add(text, due: due)
    @out.puts "added: ##{task.id} #{task.text}"
  end

  def list(args)
    show_done = args.include?("--done")
    tasks = show_done ? @store.select(&:done) : @store.reject(&:done)
    if tasks.empty?
      @out.puts "no #{show_done ? "completed" : "open"} tasks"
    else
      tasks.each { |t| @out.puts format_task(t) }
    end
  end

  def done(args)
    id = args.shift&.to_i
    abort "usage: tasks done ID" unless id&.positive?
    task = @store.mark_done(id)
    @out.puts "done: ##{task.id} #{task.text}"
  end

  def search(args)
    query = args.join(" ").downcase
    abort "usage: tasks search QUERY" if query.empty?
    matches = @store.select { |t| t.text.downcase.include?(query) }
    if matches.empty?
      @out.puts "no matches"
    else
      matches.each { |t| @out.puts format_task(t) }
    end
  end

  def stats(_args)
    by_status = @store.group_by { |t| t.done ? :done : :open }
    overdue   = @store.count(&:overdue?)
    @out.puts "open:    #{(by_status[:open] || []).length}"
    @out.puts "done:    #{(by_status[:done] || []).length}"
    @out.puts "overdue: #{overdue}"
  end

  def export(args)
    format = args.first || "csv"
    case format
    when "csv"
      require "csv"
      csv = CSV.generate { |c| c << %w[id text due done]; @store.each { |t| c << [t.id, t.text, t.due, t.done] } }
      @out.puts csv
    when "json"
      @out.puts JSON.pretty_generate(@store.map(&:to_h))
    else
      abort "unknown format: #{format} (use csv or json)"
    end
  end

  def help(_args)
    @out.puts <<~HELP
      tasks — a personal task tracker

      Usage:
        tasks add TEXT [--due YYYY-MM-DD]
        tasks list [--done]
        tasks done ID
        tasks search QUERY
        tasks stats
        tasks export [csv|json]
        tasks help
    HELP
  end

  private

  def parse_add_args(args)
    due = nil
    if (i = args.index("--due"))
      due = args[i + 1]
      args.delete_at(i + 1)
      args.delete_at(i)
    end
    text = args.join(" ")
    text = nil if text.empty?
    [text, due]
  end

  def format_task(t)
    box = t.done ? "[x]" : "[ ]"
    due = t.due ? " (due #{t.due}#{t.overdue? ? "!" : ""})" : ""
    "#{box} ##{t.id} #{t.text}#{due}"
  end
end
```

What to notice.

`public_send(cmd, args)` — the dispatcher. `cmd` is a method name on `CLI`. We could write a `case` statement; `public_send` is one line.

Per-command methods (`add`, `list`, `done`, ...) keep each command focused on one thing. Adding a command is one method definition + one entry in `COMMANDS`.

`@store.select(&:done)`, `@store.group_by { |t| ... }` — Enumerable methods on the store, working because we `include Enumerable` and define `each`. Note how `select(&:done)` reads almost like English.

`format_task` is a small helper — pull rendering out of the methods so each `list` / `search` shares the same formatting.

The heredoc `<<~HELP` strips common leading whitespace — useful for multi-line help text.

## tasks (the entry point)

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "date"
require_relative "task_store"
require_relative "cli"

store = TaskStore.new(ENV.fetch("TASKS_FILE", File.join(Dir.home, ".tasks.json")))
CLI.new(store).run(ARGV)
```

Everything is wired here. The store path comes from `TASKS_FILE` env var, falling back to `~/.tasks.json`. Then we hand `ARGV` off to the CLI.

For convenience during development, the example version (`examples/tasks.rb`) inlines everything in one file.

(Files: `examples/tasks.rb` — a single-file version; you can run it directly.)

## Trying it

```
$ TASKS_FILE=/tmp/demo.json ruby examples/tasks.rb add "buy milk"
added: #1 buy milk
$ TASKS_FILE=/tmp/demo.json ruby examples/tasks.rb add "study Ruby" --due 2026-04-30
added: #2 study Ruby
$ TASKS_FILE=/tmp/demo.json ruby examples/tasks.rb list
[ ] #1 buy milk
[ ] #2 study Ruby (due 2026-04-30)
$ TASKS_FILE=/tmp/demo.json ruby examples/tasks.rb done 1
done: #1 buy milk
$ TASKS_FILE=/tmp/demo.json ruby examples/tasks.rb stats
open:    1
done:    1
overdue: 0
$ TASKS_FILE=/tmp/demo.json ruby examples/tasks.rb export csv
id,text,due,done
1,buy milk,,true
2,study Ruby,2026-04-30,false
```

## Common pitfalls

- **Tight coupling between data and CLI.** The spec separates `TaskStore` from `CLI` for a reason: the moment they share state, every CLI tweak risks corrupting the data layer, and the data layer can never be reused (web, API, test harness). If `TaskStore` ever takes an `ARGV` or calls `puts`, you've lost the seam. Keep the dependency one-way: CLI knows about the store; the store knows nothing about the CLI.
- **Single-file scripts grow ugly fast.** `tasks.rb` is fine at 200 lines. By 500 it's a maze. Split into `task.rb`, `task_store.rb`, `cli.rb`, `tasks` (the entry point) the moment a second person needs to read it — or the moment you do, a month later.
- **No tests means breaking changes are invisible.** A two-line refactor in `mark_done` can silently break `--done` filtering. Even three Minitest assertions catch the regression *before* you push. Exercise 6 is not optional.
- **`eval` or `send` with user input.** `public_send(cmd, args)` is safe here because we whitelist via `COMMANDS.include?(cmd)`. Drop the whitelist and `tasks instance_eval ...` becomes a remote-execution hole. Never call `send`, `public_send`, or `eval` on a string the user typed without an explicit allowlist.
- **Hand-rolled `--due` parsing.** `parse_add_args` works, but every new flag doubles its complexity. See the next section.

## What I'd do differently in production

- **JSON → SQLite.** A single JSON file rewritten on every change loses data on a crash mid-write and doesn't scale past a few hundred tasks. Swap `TaskStore` for one backed by `sqlite3` (or `sequel` / Active Record). The CLI doesn't change — that's the seam paying off.
- **Tests from line one.** A `test/task_store_test.rb` driving a temp-file store. Run it with `ruby -Ilib test/task_store_test.rb`. Every CLI command gets one happy-path assertion.
- **Config in the right place.** Hard-coding `~/.tasks.json` is rude on Linux. Honor `XDG_CONFIG_HOME`:

  ```ruby
  config_home = ENV.fetch("XDG_CONFIG_HOME", File.join(Dir.home, ".config"))
  default_path = File.join(config_home, "tasks", "tasks.db")
  ```

  Fall back through `TASKS_FILE` env var, then this, then `~/.tasks.json` for legacy users.
- **Real option parsing.** `parse_add_args` is a toy. Replace with `optparse` (stdlib, ships with Ruby) or `dry-cli` (gem) and a `Cmd` subcommand pattern — one class per command, each declaring its own flags:

  ```ruby
  require "optparse"

  class AddCmd
    def call(args)
      due = nil
      OptionParser.new do |o|
        o.on("--due DATE") { |d| due = d }
      end.parse!(args)
      [args.join(" "), due]
    end
  end
  ```

  Now `tasks add "buy milk" --due 2026-04-30 --tag shopping` Just Works, and so does `--help` per command.

## What you learned

This chapter taught no new language features. What it taught is *integration* — splitting concerns into a data layer and an interface layer, dispatching commands, sharing formatting helpers, persisting state, handling errors with friendly output.

| Pattern | Where it appeared earlier |
|---|---|
| `Data.define` for value objects | Ch 5 |
| `Enumerable` + `each` | Ch 5 |
| JSON load/save with permissive failure | Ch 7 |
| `public_send` for command dispatch | Ch 6 |
| `&:method` shorthand | Ch 2 |
| `group_by` / `select` / `reject` / `count` | Ch 2-3 |
| Custom exception classes | Ch 7 |
| `ENV.fetch` with default | Ch 7 |
| Heredocs for help text | Ch 2 |

You now own a working CLI tool. You can add features. You can refactor. You can teach someone else. That's the skill bar this chapter is here to mark.

## Going deeper

- Read the `thor` gem (`gem which thor`). It's the de-facto Ruby CLI framework — Rails' generators are built on it. Compare its `desc` / `method_option` / `def add` style to your `COMMANDS` array. Notice what Thor saves you and what it costs you in indirection.
- Read `bundler`'s CLI source (`gem which bundler`, then `lib/bundler/cli.rb`). It's Thor-based. Skim three commands. Then read `tty-prompt`'s CLI surface for contrast — a smaller, plainer style.
- Replace JSON with `sqlite3` end-to-end. `gem install sqlite3`. Rewrite `TaskStore` against it. Watch what assumptions break: `@tasks` as an in-memory array, the "load all at startup, save all at change" pattern, the id-as-array-position implicit contract. The CLI shouldn't need a single change.

## Exercises

1. **`tasks edit ID NEW_TEXT`** — let the user edit a task's text in place. Starter: `exercises/1_tasks_edit.rb` (modify `tasks.rb`'s logic; add a test or two).

2. **`tasks rm ID`** — delete a task. Starter: `exercises/2_tasks_rm.rb`.

3. **Tags**: support `--tag work` on `add`, store as an array. Add `tasks list --tag work`. Starter: `exercises/3_tasks_tags.rb`.

4. **Sort**: `tasks list --sort due` orders by due date (open ones first, then sorted). Starter: `exercises/4_tasks_sort.rb`.

5. **Color output**: when stdout is a terminal (`$stdout.tty?`), color overdue items red. Hint: ANSI escape codes — `"\e[31m...\e[0m"`. Starter: `exercises/5_tasks_color.rb`.

6. **Tests**: write a Minitest spec covering `TaskStore#add`, `#mark_done`, and `#find` (raises `NotFound`). Don't actually write to disk — use a temp file. (Tests are introduced properly in Chapter 9, but try the simple form here: `require "minitest/autorun"`, `class FooTest < Minitest::Test`, `def test_foo`, `assert_equal expected, actual`.) Starter: `exercises/6_task_store_test.rb`.
