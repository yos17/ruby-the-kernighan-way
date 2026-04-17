# Exercise 5 — attr_memoized with clear_<name>
#
# Extend attr_memoized so it also defines clear_<name> that removes the cache.
#
# class User
#   attr_memoized(:expensive) { @count = (@count || 0) + 1; @count }
# end
# u = User.new
# u.expensive       # => 1
# u.expensive       # => 1 (cached)
# u.clear_expensive
# u.expensive       # => 2 (recomputed)

module Attrs
  def attr_memoized(name, &block)
    define_method(name) do
      ivar = "@#{name}"
      return instance_variable_get(ivar) if instance_variable_defined?(ivar)
      value = instance_eval(&block)
      instance_variable_set(ivar, value)
      value
    end

    # TODO: define clear_<name> that removes_instance_variable
  end
end

class Class
  include Attrs
end
