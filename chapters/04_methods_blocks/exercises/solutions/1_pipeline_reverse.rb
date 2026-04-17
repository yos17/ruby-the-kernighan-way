# Solution to Exercise 1
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

  def reverse_steps
    Pipeline.new(*@steps.reverse)
  end
end

if __FILE__ == $PROGRAM_NAME
  add_one   = ->(n) { n + 1 }
  multi_two = ->(n) { n * 2 }

  p = Pipeline.new(add_one, multi_two)
  puts p.call(3)                # (3+1)*2 = 8
  puts p.reverse_steps.call(3)  # (3*2)+1 = 7
end
