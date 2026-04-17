# pipeline.rb — chain transformations together
# Usage: ruby pipeline.rb (demo)

# Pipeline — chains any number of "steps" (lambdas or procs)
# together, so the output of one feeds into the input of the next.
# Great for data transformation: clean → parse → summarise.
class Pipeline
  # `*steps` is a splat: it collects every argument into an array,
  # so `Pipeline.new(a, b, c)` stores [a, b, c] in @steps.
  def initialize(*steps)
    @steps = steps
  end

  # `reduce(input)` starts with `input` as the accumulator, then
  # runs the block once per step — each call feeds the previous
  # result forward. Classic fold/reduce pattern.
  def call(input)
    @steps.reduce(input) { |value, step| step.call(value) }
  end

  # Return a *new* pipeline with one extra step appended to the end.
  # We never mutate @steps — building new pipelines means you can
  # share and extend them without surprises. `*@steps` splats the
  # array back into individual arguments.
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
