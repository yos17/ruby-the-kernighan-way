# mini_attr.rb — your own attribute generators
# Usage: ruby mini_attr.rb (demo)

module Attrs
  def attr_logged(*names)
    names.each do |name|
      define_method(name) { instance_variable_get("@#{name}") }
      define_method("#{name}=") do |value|
        puts "[set] #{self.class}##{name} = #{value.inspect}"
        instance_variable_set("@#{name}", value)
      end
    end
  end

  def attr_typed(name, type)
    define_method(name) { instance_variable_get("@#{name}") }
    define_method("#{name}=") do |value|
      raise TypeError, "#{name} expected #{type}, got #{value.class}" unless value.is_a?(type)
      instance_variable_set("@#{name}", value)
    end
  end

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
