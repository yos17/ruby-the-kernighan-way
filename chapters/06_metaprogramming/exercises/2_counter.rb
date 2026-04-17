# Exercise 2 — Counter
#
# c = Counter.new
# c.signups       # => 0
# c.signups!      # => 1
# c.signups!      # => 2
# c.failures      # => 0
# c.failures!     # => 1
#
# Use method_missing to support arbitrary counter names.

class Counter
  def initialize
    @counts = Hash.new(0)
  end

  # TODO: method_missing(name, *args)
  # TODO: respond_to_missing?(name, include_private = false)
end
