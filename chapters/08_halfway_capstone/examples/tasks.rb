#!/usr/bin/env ruby
# tasks.rb — a personal task tracker (single-file version of the capstone)
# Usage: ruby tasks.rb (add|list|done|search|stats|export|help) [args]

require "json"
require "date"

Task = Data.define(:id, :text, :due, :done) do
  def to_h = { id: id, text: text, due: due, done: done }
  def overdue? = due && !done && Date.parse(due) < Date.today
end

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

if __FILE__ == $PROGRAM_NAME
  store = TaskStore.new(ENV.fetch("TASKS_FILE", File.join(Dir.home, ".tasks.json")))
  CLI.new(store).run(ARGV)
end
