# Exercise 3 — memoize with bounded cache (LRU eviction)
#
# Extend memoize to take a max_size: keyword argument. When the cache exceeds
# that many entries, drop the oldest entry (FIFO/LRU).
#
# Hint: cache is a Hash, which preserves insertion order. cache.shift removes
# the oldest [key, value] pair.

def memoize(fn, max_size: nil)
  cache = {}
  ->(*args) {
    # TODO: lookup; on miss, compute; if cache size exceeds max_size, evict oldest
    cache.fetch(args) { cache[args] = fn.call(*args) }
  }
end
