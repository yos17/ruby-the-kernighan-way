# mini_attr.rb — your own attribute generators
# Usage: ruby mini_attr.rb (demo)

# Attrs — a module of "attribute macros". Each method generates
# getter and setter methods on the fly, the same way Ruby's
# built-in `attr_accessor` does. This is how Rails builds things
# like `belongs_to` and `validates`.
module Attrs
  # `define_method(name) { ... }` creates a real instance method
  # at runtime with the given name and body. `instance_variable_get`
  # and `..._set` read/write @-variables when you only know the
  # name as a string.
  def attr_logged(*names)
    names.each do |name|
      define_method(name) { instance_variable_get("@#{name}") }
      define_method("#{name}=") do |value|
        puts "[set] #{self.class}##{name} = #{value.inspect}"
        instance_variable_set("@#{name}", value)
      end
    end
  end

  # Build a reader and a type-checking writer for one attribute.
  def attr_typed(name, type)
    define_method(name) { instance_variable_get("@#{name}") }
    define_method("#{name}=") do |value|
      raise TypeError, "#{name} expected #{type}, got #{value.class}" unless value.is_a?(type)
      instance_variable_set("@#{name}", value)
    end
  end

  # Build a reader that computes its value once and then reuses it.
  # The block passed by the caller becomes the "how to compute it"
  # recipe. `instance_eval(&block)` runs that block in the context
  # of the *current object*, so `self` inside the block is the
  # instance, not the class where the macro was called.
  def attr_memoized(name, &block)
    define_method(name) do
      ivar = "@#{name}"
      return instance_variable_get(ivar) if instance_variable_defined?(ivar)
      value = instance_eval(&block)
      instance_variable_set(ivar, value)
      value
    end
  end
end

# Reopening the built-in `Class` and mixing `Attrs` in means every
# class definition in the program now has access to `attr_logged`,
# `attr_typed`, and `attr_memoized` — just like `attr_accessor`.
# This is the "monkey-patching" super-power: use it sparingly.
class Class
  include Attrs
end

if __FILE__ == $PROGRAM_NAME
  class User
    attr_logged :name
    attr_typed  :age, Integer
    attr_memoized(:expensive) {
      puts "[compute] expensive once"
      42
    }
  end

  u = User.new
  u.name = "Yosia"
  u.age  = 30
  begin
    u.age = "thirty"
  rescue TypeError => e
    puts "caught: #{e.message}"
  end
  puts u.expensive
  puts u.expensive
end
