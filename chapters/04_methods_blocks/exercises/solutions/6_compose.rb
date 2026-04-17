# Solution to Exercise 6
def compose_left(*fns)
  ->(x) { fns.reduce(x) { |v, f| f.call(v) } }
end

def compose_right(*fns)
  ->(x) { fns.reverse.reduce(x) { |v, f| f.call(v) } }
end

if __FILE__ == $PROGRAM_NAME
  add_one   = ->(n) { n + 1 }
  multi_two = ->(n) { n * 2 }

  puts compose_left(add_one, multi_two).call(3)   # (3+1)*2 = 8
  puts compose_right(add_one, multi_two).call(3)  # (3*2)+1 = 7
end
