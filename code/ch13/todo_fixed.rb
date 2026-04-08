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
