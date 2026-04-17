# Solution to Exercise 5
module Attrs
  def attr_memoized(name, &block)
    ivar = "@#{name}"

    define_method(name) do
      return instance_variable_get(ivar) if instance_variable_defined?(ivar)
      value = instance_eval(&block)
      instance_variable_set(ivar, value)
      value
    end

    define_method("clear_#{name}") do
      remove_instance_variable(ivar) if instance_variable_defined?(ivar)
      nil
    end
  end
end

class Class
  include Attrs
end

if __FILE__ == $PROGRAM_NAME
  class User
    attr_memoized(:expensive) {
      @count = (@count || 0) + 1
      @count
    }
  end

  u = User.new
  puts u.expensive       # 1
  puts u.expensive       # 1 (cached)
  u.clear_expensive
  puts u.expensive       # 2 (recomputed)
end
