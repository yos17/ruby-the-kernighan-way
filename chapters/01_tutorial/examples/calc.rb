# calc.rb — a calculator that takes two numbers and an operator from ARGV
# Usage: ruby calc.rb <a> <op> <b>
#   ruby calc.rb 10 + 5    # => 15.0
#   ruby calc.rb 10 / 4    # => 2.5
#   ruby calc.rb 10 / 0    # => Cannot divide by zero
#   ruby calc.rb 10 % 5    # => Unknown operator: %

# Apply the chosen operator and return either the numeric result
# or an error message. `case/when` is Ruby's multi-way branch — a
# cleaner form than a chain of if/elsif.
def calculate(a, op, b)
  case op
  when "+" then a + b
  when "-" then a - b
  when "*" then a * b
  when "/"
    # Guard against divide-by-zero before it blows up. `return`
    # exits the method early with the error string.
    return "Cannot divide by zero" if b == 0
    a / b
  else
    # Fall-through for any operator we don't recognise.
    "Unknown operator: #{op}"
  end
end

# `.to_f` converts the string from ARGV to a floating-point
# number. If the user typed "hi" instead of "3", you get 0.0.
a  = ARGV[0].to_f
op = ARGV[1]
b  = ARGV[2].to_f

puts calculate(a, op, b)
