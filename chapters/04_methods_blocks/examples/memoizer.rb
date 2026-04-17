# memoizer.rb — wrap any callable with a result cache
# Usage: ruby memoizer.rb (demo)

# Wrap a callable so repeated calls with the same arguments reuse
# the cached result. The returned lambda "closes over" the local
# `cache` hash — every invocation of `memoize` gets its own cache,
# and that cache survives as long as the lambda does. This is
# called a *closure* and is one of Ruby's quietly powerful ideas.
def memoize(fn)
  cache = {}
  # `->(*args) { ... }` creates a lambda (a small anonymous function)
  # that accepts any number of arguments as an array.
  #
  # `cache.fetch(args) { ... }` means: "give me the value for `args`
  # if it's there; otherwise run the block, store its result, and
  # return that". The block version of fetch is the standard "lazy
  # initialize on first access" Ruby pattern.
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
