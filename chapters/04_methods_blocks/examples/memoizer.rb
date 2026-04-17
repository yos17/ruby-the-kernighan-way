# memoizer.rb — wrap any callable with a result cache
# Usage: ruby memoizer.rb (demo)

def memoize(fn)
  cache = {}
  ->(*args) { cache.fetch(args) { cache[args] = fn.call(*args) } }
end

if __FILE__ == $PROGRAM_NAME
  slow_square = ->(n) {
    sleep 0.1
    n * n
  }

  fast_square = memoize(slow_square)

  require "benchmark"
  puts Benchmark.measure { 5.times { fast_square.call(4) } }
  puts fast_square.call(4)
  puts fast_square.call(5)
  puts fast_square.call(4)
end
