# Solution to Exercise 1
name = ARGV[0]
time = ARGV[1]

greeting = case time
           when "morning"   then "Good morning"
           when "afternoon" then "Good afternoon"
           when "evening"   then "Good evening"
           else                  "Hello"
           end

puts "#{greeting}, #{name}!"
