# Solution to Exercise 4
class Stepper
  include Enumerable

  def initialize(start, stop, step = 1)
    @start = start
    @stop  = stop
    @step  = step
  end

  def each
    n = @start
    while n <= @stop
      yield n
      n += @step
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  puts Stepper.new(0, 10, 2).to_a.inspect
  puts Stepper.new(1, 10).count
  puts Stepper.new(1, 10).sum
end
