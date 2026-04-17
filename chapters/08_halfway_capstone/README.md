# Chapter 8 — Halfway Capstone: a Real CLI Tool

The first seven chapters taught separate moves. This chapter makes them work together. The result is `tasks`, a small command-line task tracker that reads and writes a JSON file, searches, filters, prints summaries, and stays small enough to understand in one sitting.

Almost nothing here is conceptually new. That is good news. A capstone should feel like familiar pieces clicking together, not a fresh pile of syntax.

## What `tasks` does

Read these commands as the program's spec:

```
$ tasks add "buy milk"                     # add a task
$ tasks add "study Ruby" --due 2026-04-30 # add one with a due date
$ tasks list                               # show open tasks
$ tasks list --done                        # show completed tasks
$ tasks done 2                             # mark task #2 done
$ tasks search milk                        # filter by keyword
$ tasks stats                              # print a summary
$ tasks export csv > out.csv               # export
```

Tasks live in a JSON file (`~/.tasks.json` by default, or wherever `TASKS_FILE` env var points).

After the first two `add` commands, the file looks like:

```json
[
  {
    "id": 1,
    "text": "buy milk",
    "due": null,
    "done": false
  },
  {
    "id": 2,
    "text": "study Ruby",
    "due": "2026-04-30",
    "done": false
  }
]
```

Two parts keep the program readable:

- `TaskStore` owns loading, saving, and updating tasks.
- `CLI` owns `ARGV`, command dispatch, and terminal output.

That split is enough. The store should never call `puts`. The CLI should never reach into JSON parsing.

## Task — one task in memory

```ruby
Task = Data.define(:id, :text, :due, :done) do
  def to_h = { id: id, text: text, due: due, done: done }
  def overdue? = due && !done && Date.parse(due) < Date.today
end
```

`Data.define` (Ch 5) gives a compact value object. A task is just data with two small bits of behavior attached: `to_h` for saving and `overdue?` for display.

`Data` instances are immutable. That matters later: when a task changes, we replace it with a new one instead of mutating it in place.

## TaskStore — the part that touches disk

```ruby
class TaskStore
  include Enumerable

  class NotFound < StandardError; end

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
    idx = @tasks.index(task)
    new_task = Task.new(**task.to_h.merge(done: true))
    @tasks[idx] = new_task
    save
    new_task
  end

  def each(&block) = @tasks.each(&block)

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

- `include Enumerable` plus `each` buys us `select`, `reject`, `group_by`, `count`, and friends for free.
- `load` and `save` are the only methods that touch the file. Keep it that way.
- `mark_done` replaces one `Task` with another because `Data` instances are immutable.
- `NotFound` lets the CLI print a friendly message instead of a backtrace.

## CLI — the part that talks to the user

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
      csv = CSV.generate do |c|
        c << %w[id text due done]
        @store.each { |t| c << [t.id, t.text, t.due, t.done] }
      end
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

- `COMMANDS` is an allowlist. Keep it. Without it, `public_send` would happily call methods you never meant to expose.
- Each command is one small method. That is what keeps the file readable.
- `format_task` keeps display choices in one place.
- `parse_add_args` is crude, but readable, and good enough while there is only one flag.

## The entry point

```ruby
if __FILE__ == $PROGRAM_NAME
  store = TaskStore.new(ENV.fetch("TASKS_FILE", File.join(Dir.home, ".tasks.json")))
  CLI.new(store).run(ARGV)
end
```

`$PROGRAM_NAME` is the file Ruby started with. The guard means the code runs when you execute the file directly, not when some other file `require`s it.

`ENV.fetch("TASKS_FILE", ...)` gives you a convenient override for testing. The example commands below use that so you do not scribble over a real task file while experimenting.

The example version in `examples/tasks.rb` keeps everything in one file. That is deliberate. At this size, one file is still easier to read than four.

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

- **Mixing storage and terminal code.** If `TaskStore` starts calling `puts`, or if `CLI` starts editing `@tasks` directly, the program becomes harder to change than it needs to be.
- **Forgetting that `Data` is immutable.** `task.done = true` is not an option here. You replace the task with a new value.
- **Dispatching user input without an allowlist.** `public_send` is safe here only because `COMMANDS` limits what can be called.
- **Letting one command grow into a parser, formatter, and store update all at once.** Pull helpers like `format_task` out early.
- **Hand-rolled flag parsing gets brittle.** `parse_add_args` is fine for one flag. It stops being fine the moment you add three more.

## What you learned

This chapter adds almost no new syntax. Its job is harder than that: keep a whole program legible.

| Idea | Where it pays off here |
|---|---|
| `Data.define` | a task is a small value object |
| `Enumerable` + `each` | the store gets filtering and counting for free |
| `JSON.parse` / `JSON.pretty_generate` | tasks persist between runs |
| Custom exception class | missing ids become friendly errors |
| `public_send` + allowlist | commands dispatch cleanly |
| `group_by`, `select`, `reject`, `count` | stats and filtering stay short |
| `ENV.fetch` | the task file is configurable |
| Small helper methods | commands stay readable |

You now have a tool that is worth extending. That is the bar this chapter is here to mark.

## Going deeper

- Replace the JSON file with SQLite. The interesting part is not the database code. It is whether the CLI needs to change. Ideally it does not.
- Read the source of a real Ruby CLI. `thor` and Bundler are obvious choices. Compare their command dispatch to your `COMMANDS` array.
- Split `examples/tasks.rb` into `task.rb`, `task_store.rb`, `cli.rb`, and a small executable. Chapter 9 turns that move into a gem.

## Exercises

1. **`tasks edit ID NEW_TEXT`** — let the user change a task's text without changing anything else. Starter: `exercises/1_tasks_edit.rb`.

2. **`tasks rm ID`** — delete a task. Starter: `exercises/2_tasks_rm.rb`.

3. **Tags**: support `--tag work` on `add`, store tags as an array, and add `tasks list --tag work`. Starter: `exercises/3_tasks_tags.rb`.

4. **Sort**: `tasks list --sort due` orders by due date (open ones first, then sorted). Starter: `exercises/4_tasks_sort.rb`.

5. **Color output**: when stdout is a terminal (`$stdout.tty?`), color overdue items red. Hint: ANSI escape codes — `"\e[31m...\e[0m"`. Starter: `exercises/5_tasks_color.rb`.

6. **Tests**: write a small Minitest file covering `TaskStore#add`, `#mark_done`, and `#find` raising `NotFound`. Use a temp file instead of a real task file. Starter: `exercises/6_task_store_test.rb`.
