# irb_debug_demo.rb — binding.irb with debug gem stepping
# Ruby 3.3+ merges IRB's REPL with the debug gem's stepping.
# No extra gems needed — it's all built in.
#
# Run: ruby irb_debug_demo.rb
#
# When you hit binding.irb, you get a full REPL AND stepping:
#
#   irb> name          # inspect variables (like Pry)
#   irb> ls            # list methods (like Pry)
#   irb> show_source   # view source code (like Pry)
#   irb> step          # step into method (from debug gem)
#   irb> next          # step over (from debug gem)
#   irb> continue      # continue execution (from debug gem)
#   irb> finish        # finish current method (from debug gem)
#   irb> info          # show all local variables (from debug gem)
#   irb> break 30      # set breakpoint at line 30 (from debug gem)
#   irb> backtrace     # show call stack (from debug gem)

class ShoppingCart
  attr_reader :items

  def initialize
    @items = []
  end

  def add(name, price, qty = 1)
    @items << { name: name, price: price, qty: qty }
  end

  def subtotal
    @items.sum { |item| item[:price] * item[:qty] }
  end

  def apply_discount(percent)
    factor = (100 - percent) / 100.0
    @items.each do |item|
      item[:price] = (item[:price] * factor).round(2)
    end
  end

  def checkout
    binding.irb   # ← pause here: inspect, step, continue — all in one REPL
    total = subtotal
    tax = (total * 0.1).round(2)
    { subtotal: total, tax: tax, total: (total + tax).round(2) }
  end
end

cart = ShoppingCart.new
cart.add("Ruby book", 29.99)
cart.add("Coffee", 4.50, 3)
cart.apply_discount(10)

result = cart.checkout
puts "Subtotal: $#{result[:subtotal]}"
puts "Tax:      $#{result[:tax]}"
puts "Total:    $#{result[:total]}"
