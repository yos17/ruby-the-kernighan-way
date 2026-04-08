# todo_buggy.rb — a todo list with 3 hidden bugs
# Your mission: find and fix them using Pry or the VSCode debugger
#
# To debug with binding.irb (built in, no gems needed):
#   Add "binding.irb" where you want to pause
#   Run: ruby todo_buggy.rb
#   Use: step, next, continue, info in the REPL
#
# To debug with VSCode:
#   Open this file, set breakpoints, press F5

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
    item[:done] = true                     # BUG 1: crashes if task not found
    puts "Completed: #{task_name}"
  end

  def pending
    @items.select { |i| i[:done] }         # BUG 2: returns done items, not pending
  end

  def summary
    total = @items.length
    done = @items.count { |i| i[:done] }
    pending = total - done
    percent = (done / total * 100).round    # BUG 3: integer division
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
