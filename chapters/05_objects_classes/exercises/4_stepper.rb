# Exercise 4 — Stepper
#
# Yield start, start+step, start+2*step, ..., up to and including stop.
# Default step is 1.
#
# Stepper.new(0, 10, 2).to_a   # => [0, 2, 4, 6, 8, 10]
# Stepper.new(1, 10).to_a      # => [1, 2, ..., 10]
#
# Include Enumerable. The .to_a / .map / .select methods come for free
# once you implement each.

class Stepper
  include Enumerable

  def initialize(start, stop, step = 1)
    @start = start
    @stop  = stop
    @step  = step
  end

  # TODO: def each
end
