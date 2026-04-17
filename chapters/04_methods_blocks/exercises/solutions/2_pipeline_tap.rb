# Solution to Exercise 2
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

  def tap_with(&block)
    Pipeline.new(*@steps, ->(v) { block.call(v); v })
  end
end

if __FILE__ == $PROGRAM_NAME
  add_one = ->(n) { n + 1 }
  result = Pipeline.new(add_one).tap_with { |v| puts "value is #{v}" }.call(5)
  puts "returned #{result}"
end
