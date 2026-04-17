# Exercise 1 — histogram from stdin
#
# Extend histogram.rb to read from stdin when no filename is given.
# Examples:
#   ruby exercises/1_histogram_stdin.rb examples/colors.txt
#   cat examples/colors.txt | ruby exercises/1_histogram_stdin.rb

# TODO: choose between File.readlines and STDIN.readlines based on ARGV
# TODO: keep the rest of the histogram logic the same

lines = []  # placeholder
counts = lines.tally

counts.sort_by { |_value, count| -count }.each do |value, count|
  bar = "#" * count
  puts "#{value.ljust(15)} #{bar} #{count}"
end
