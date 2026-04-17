# histogram.rb — print a horizontal bar chart of value frequencies
# Usage: ruby histogram.rb <file>

filename = ARGV[0]

# `readlines` returns an array of lines (`chomp: true` strips the
# trailing newlines). `.tally` turns an array into a hash counting
# how many times each element appears: ["a","b","a"] => {"a"=>2, "b"=>1}.
counts = File.readlines(filename, chomp: true).tally

# Sort descending by count. The underscore prefix on `_value` is a
# convention that says "I know I'm not using this variable" — it
# silences linter warnings and signals intent to human readers.
counts.sort_by { |_value, count| -count }.each do |value, count|
  # "#" * count repeats the character. 7 => "#######".
  # `ljust(15)` pads the value on the right with spaces so the
  # bars line up into a neat column.
  bar = "#" * count
  puts "#{value.ljust(15)} #{bar} #{count}"
end
