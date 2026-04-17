# Solution to Exercise 3
if ARGV.length != 3
  puts "Usage: ruby calc.rb <a> <op> <b>"
  exit 1
end

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
