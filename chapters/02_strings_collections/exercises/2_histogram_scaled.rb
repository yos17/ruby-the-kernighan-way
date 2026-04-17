# Exercise 2 — histogram with a width cap
#
# Scale bars so the longest bar is at most 40 characters wide.
# Print the scaled bar plus the actual count.
# Useful for files where some values appear thousands of times.
#
# Example: if the highest count is 100, each "#" represents 100/40 = 2.5 occurrences.
# Round the bar length up so a count of 1 still prints at least one "#".

filename = ARGV[0]
counts = File.readlines(filename, chomp: true).tally

# TODO: find the max count
# TODO: compute a scale factor so max_count maps to ~40 chars
# TODO: in the loop, scale each count to determine bar length

counts.sort_by { |_value, count| -count }.each do |value, count|
  bar = "#" * count   # TODO: replace with scaled length
  puts "#{value.ljust(15)} #{bar} #{count}"
end
