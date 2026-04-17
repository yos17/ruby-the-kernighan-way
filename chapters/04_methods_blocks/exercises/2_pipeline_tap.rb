# Exercise 2 — Pipeline#tap_with
#
# Add a tap_with(&block) method that inserts a side-effect step.
# The block is called with the current value; the value is unchanged.
#
# Example:
#   Pipeline.new(add_one).tap_with { |v| puts "value is #{v}" }.call(5)
#   #=> prints "value is 6"
#   #=> returns 6

class Pipeline
  def initialize(*steps)
    @steps = steps
  end

  def call(input)
    @steps.reduce(input) { |value, step| step.call(value) }
  end

  def then(step)
    Pipeline.new(*@steps, step)
  end

  # TODO: def tap_with(&block)
end
