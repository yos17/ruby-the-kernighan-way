name    = "Yosia"       # String
age     = 30            # Integer
height  = 1.75          # Float
active  = true          # Boolean (TrueClass)
nothing = nil           # Null (NilClass)

puts name               # Yosia
puts age + 1            # 31
puts "Name: #{name}"    # Name: Yosia   (string interpolation)
puts "Age: " + age.to_s # Age: 30       (explicit conversion)