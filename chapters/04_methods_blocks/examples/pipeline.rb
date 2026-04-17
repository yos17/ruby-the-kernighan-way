# pipeline.rb — chain transformations together
# Usage: ruby pipeline.rb (demo)

class Pipeline
  # Store the callables in the order they should run.
  def initialize(*steps)
    @steps = steps
  end

  # Feed the input through each step and return the final value.
  def call(input)
    @steps.reduce(input) { |value, step| step.call(value) }
  end

  # Return a new pipeline with one extra step appended to the end.
  def then(step)
    Pipeline.new(*@steps, step)
  end
end

if __FILE__ == $PROGRAM_NAME
  strip_whitespace = ->(s) { s.strip }
  to_lower         = ->(s) { s.downcase }
  remove_punct     = ->(s) { s.gsub(/[[:punct:]]/, "") }
  words            = ->(s) { s.split }
  top_3            = ->(arr) { arr.tally.sort_by { |w, c| [-c, w] }.first(3) }

  clean = Pipeline.new(strip_whitespace, to_lower, remove_punct)
  top_words = clean.then(words).then(top_3)

  p top_words.call("  Hello, hello! World hello world.  ")
end
