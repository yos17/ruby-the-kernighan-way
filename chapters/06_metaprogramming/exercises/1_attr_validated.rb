# Exercise 1 — attr_validated(name, &block)
#
# attr_validated :age do |v|
#   v.is_a?(Integer) && v >= 0
# end
# Calling user.age = -5 should raise (block returns false).

module Attrs
  # Reuse the existing attr_logged/typed/memoized
  def attr_logged(*names); end
  def attr_typed(name, type); end
  def attr_memoized(name, &block); end

  # TODO: def attr_validated(name, &validator)
end

class Class
  include Attrs
end
