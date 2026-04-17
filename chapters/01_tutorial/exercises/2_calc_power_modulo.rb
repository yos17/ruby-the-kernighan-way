# Exercise 2 — calc.rb with ** (power) and % (modulo)
#
# Add support for two new operators to the calculator:
#   ruby exercises/2_calc_power_modulo.rb 2 ** 10   # => 1024.0
#   ruby exercises/2_calc_power_modulo.rb 17 % 5    # => 2.0
#
# Existing operators (+ - * /) should still work.

def calculate(a, op, b)
  case op
  when "+" then a + b
  when "-" then a - b
  when "*" then a * b
  when "/"
    return "Cannot divide by zero" if b == 0
    a / b
  # TODO: add a `when "**"` branch
  # TODO: add a `when "%"` branch
  else
    "Unknown operator: #{op}"
  end
end

a  = ARGV[0].to_f
op = ARGV[1]
b  = ARGV[2].to_f

puts calculate(a, op, b)
