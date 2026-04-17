# Solution to Exercise 3
def memoize(fn, max_size: nil)
  cache = {}
  ->(*args) {
    if cache.key?(args)
      cache[args]
    else
      result = fn.call(*args)
      cache[args] = result
      cache.shift if max_size && cache.size > max_size
      result
    end
  }
end

if __FILE__ == $PROGRAM_NAME
  square = ->(n) { n * n }
  bounded = memoize(square, max_size: 2)

  bounded.call(1)
  bounded.call(2)
  bounded.call(3)   # evicts (1)
  bounded.call(1)   # cache miss, recomputes
  puts "ok"
end
