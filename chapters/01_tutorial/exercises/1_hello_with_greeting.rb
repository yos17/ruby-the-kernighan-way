# Exercise 1 — hello.rb with a time-of-day greeting
#
# Extend hello.rb to accept name AND time-of-day as arguments.
# Examples:
#   ruby exercises/1_hello_with_greeting.rb Yosia morning   # => Good morning, Yosia!
#   ruby exercises/1_hello_with_greeting.rb Yosia afternoon # => Good afternoon, Yosia!
#   ruby exercises/1_hello_with_greeting.rb Yosia evening   # => Good evening, Yosia!
#   ruby exercises/1_hello_with_greeting.rb Yosia           # => Hello, Yosia!  (no time given)
#
# Hint: ARGV[0] is the name, ARGV[1] is the time. Use case/when on the time.

name = ARGV[0]
time = ARGV[1]

# TODO: build the greeting string based on `time`
# TODO: handle the case where `time` is nil (no second argument)
# TODO: print the greeting
