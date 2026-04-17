# calc.rb — a calculator that takes two numbers and an operator from ARGV
# Usage: ruby calc.rb <a> <op> <b>
#   ruby calc.rb 10 + 5    # => 15.0
#   ruby calc.rb 10 / 4    # => 2.5
#   ruby calc.rb 10 / 0    # => Cannot divide by zero
#   ruby calc.rb 10 % 5    # => Unknown operator: %

# Apply the chosen operator and return either the numeric result or an error message.
def calculate(a, op, b)
  case op
  when "+" then a + b
  when "-" then a - b
  when "*" then a * b
  when "/"
    return "Cannot divide by zero" if b == 0
    a / b
  else
    "Unknown operator: #{op}"
  end
end

a  = ARGV[0].to_f
op = ARGV[1]
b  = ARGV[2].to_f

puts calculate(a, op, b)
