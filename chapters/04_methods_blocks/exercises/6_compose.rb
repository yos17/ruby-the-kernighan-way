# Exercise 6 — compose.rb
#
# Write compose_left(*fns) that chains lambdas left-to-right:
#   compose_left(a, b, c).call(x) == c.call(b.call(a.call(x)))
# (Same as a Pipeline.)
#
# Also write compose_right(*fns) for right-to-left (the math convention):
#   compose_right(a, b, c).call(x) == a.call(b.call(c.call(x)))

# TODO: def compose_left(*fns); end
# TODO: def compose_right(*fns); end

if __FILE__ == $PROGRAM_NAME
  add_one   = ->(n) { n + 1 }
  multi_two = ->(n) { n * 2 }

  # left  := add_one then multi_two: (3+1)*2 = 8
  # right := add_one of multi_two:   (3*2)+1 = 7
  # puts compose_left(add_one, multi_two).call(3)
  # puts compose_right(add_one, multi_two).call(3)
end
