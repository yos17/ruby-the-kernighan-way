

def check_age(name, age)
  binding.irb
  if age >=18 
    "#{name} is an adult"
  else 
    "#{name} is a minor"
  end
end

puts check_age("Alice", 25)
puts check_age("Bob", 15)