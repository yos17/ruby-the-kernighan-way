# Exercise 3 — calc.rb usage message
#
# When ARGV doesn't have exactly three items, print a usage message and exit.
# Examples:
#   ruby exercises/3_calc_usage_message.rb              # => Usage: ruby calc.rb <a> <op> <b>  (then exits)
#   ruby exercises/3_calc_usage_message.rb 10 +         # => Usage: ruby calc.rb <a> <op> <b>  (then exits)
#   ruby exercises/3_calc_usage_message.rb 10 + 5       # => 15.0  (works as before)
#
# Hint: `ARGV.length` and `exit 1` (the 1 means "non-zero exit code = error").

# TODO: check ARGV.length, print usage and exit if wrong
# TODO: then do the normal calculation
