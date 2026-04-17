# Solution to Exercise 2
MAX_WIDTH = 40

filename = ARGV[0]
counts = File.readlines(filename, chomp: true).tally

max_count = counts.values.max
scale = max_count > MAX_WIDTH ? max_count.to_f / MAX_WIDTH : 1.0

counts.sort_by { |_value, count| -count }.each do |value, count|
  bar_length = (count / scale).ceil
  bar = "#" * bar_length
  puts "#{value.ljust(15)} #{bar} #{count}"
end
