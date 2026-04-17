# calculator.rb - a simple calculator

print "First number:"
a = gets.chomp.to_f

print "Operator (+, -, *, /, **, %):"
op = gets.chomp 

print "Second number: "
b = gets.chomp.to_f

result =  case op
          when "+" then a + b 
          when "-" then a - b 
          when "*" then a * b 
          when "**" then a ** b 
          when "%" then a % b
          when "/" then 
            if b == 0
              "Error: division by zero"
            else 
              a / b
            end
          else
            "Unknown operator: #{op}" 
          end 

puts "Result: #{result}"
