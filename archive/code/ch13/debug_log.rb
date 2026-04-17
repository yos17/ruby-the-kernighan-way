# debug_log.rb — a mini debug helper (Exercise 4 solution)

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

Order.new(42, [{ name: "Book", price: 15 }, { name: "Pen", price: 3 }]).debug
# [DEBUG Order] @id=42 @items=[{:name=>"Book", :price=>15}, {:name=>"Pen", :price=>3}] @total=18
