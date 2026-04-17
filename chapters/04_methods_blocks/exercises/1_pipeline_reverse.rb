# Exercise 1 — Pipeline#reverse_steps
#
# Add a reverse_steps method that returns a new Pipeline with steps reversed.

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

  # TODO: def reverse_steps
end

if __FILE__ == $PROGRAM_NAME
  add_one    = ->(n) { n + 1 }
  multi_two  = ->(n) { n * 2 }

  p = Pipeline.new(add_one, multi_two)
  puts p.call(3)                # (3+1)*2 = 8
  # TODO: puts p.reverse_steps.call(3)  # (3*2)+1 = 7
end
