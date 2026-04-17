# Solution to Exercise 1
module Attrs
  def attr_validated(name, &validator)
    define_method(name) { instance_variable_get("@#{name}") }
    define_method("#{name}=") do |value|
      raise ArgumentError, "invalid #{name}: #{value.inspect}" unless validator.call(value)
      instance_variable_set("@#{name}", value)
    end
  end
end

class Class
  include Attrs
end

if __FILE__ == $PROGRAM_NAME
  class User
    attr_validated(:age) { |v| v.is_a?(Integer) && v >= 0 }
  end

  u = User.new
  u.age = 30
  puts u.age
  begin
    u.age = -5
  rescue ArgumentError => e
    puts "caught: #{e.message}"
  end
end
