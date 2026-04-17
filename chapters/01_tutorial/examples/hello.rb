# hello.rb — interactive greeter
# Usage: ruby hello.rb

# `print` writes without a trailing newline, so the cursor sits
# right after the question — nicer for an interactive prompt.
print "What is your name? "

# `gets` reads one line from the keyboard (up to and including
# the newline the user types). `.chomp` removes that trailing
# newline so we don't greet "Yosia\n".
name = gets.chomp

# Inside a double-quoted string, "#{name}" is string interpolation:
# Ruby replaces it with the value of the `name` variable.
puts "Hello, #{name}!"
